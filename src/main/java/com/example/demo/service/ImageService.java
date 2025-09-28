package com.example.demo.service;

import com.example.demo.model.Image;
import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;

import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.ScanEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.util.List;

@Service
public class ImageService {

    private final DynamoDbTemplate dynamoDbTemplate;

    @Autowired
    public ImageService(DynamoDbTemplate dynamoDbTemplate) {
        this.dynamoDbTemplate = dynamoDbTemplate;
    }

    public Image create(Image image) {
        dynamoDbTemplate.save(image);
        return image;
    }

    public Image getById(String id) {
        Key key = Key.builder().partitionValue(id).build();
        return dynamoDbTemplate.load(key, Image.class);
    }

    public void deleteById(String id) {
        Key key = Key.builder().partitionValue(id).build();
        dynamoDbTemplate.delete(key, Image.class);
    }

    public List<Image> searchByLabel(String label) {
      Expression expression = Expression.builder()
          .expression("contains(#labels, :label)")
          .putExpressionName("#labels", "labels")
          .putExpressionValue(":label", AttributeValue.builder().s(label).build())
          .build();

      ScanEnhancedRequest scanRequest = ScanEnhancedRequest
          .builder()
          .filterExpression(expression)
          .build();

      return dynamoDbTemplate.scan(scanRequest, Image.class)
          .stream()
          .flatMap(page -> page.items().stream())
          .toList();
    }
}