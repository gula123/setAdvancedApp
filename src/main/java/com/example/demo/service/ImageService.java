package com.example.demo.service;

import com.example.demo.model.Image;
import com.example.demo.model.Status;
import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import io.awspring.cloud.s3.S3Template;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.multipart.MultipartFile;

import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.ScanEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class ImageService {

    private final DynamoDbTemplate dynamoDbTemplate;
    private final S3Template s3Template;
    private static final String BUCKET_NAME = "images-bucket";

    @Autowired
    public ImageService(DynamoDbTemplate dynamoDbTemplate, S3Template s3Template) {
        this.dynamoDbTemplate = dynamoDbTemplate;
        this.s3Template = s3Template;
    }

    public Image create(MultipartFile file) throws IOException {
        // Generate unique ID for the image
        UUID imageId = UUID.randomUUID();
        String objectKey = "images/" + imageId.toString() + "_" + file.getOriginalFilename();
        
        // Ensure bucket exists
        if (!s3Template.bucketExists(BUCKET_NAME)) {
            s3Template.createBucket(BUCKET_NAME);
        }
        
        // Upload file to S3
        try {
            s3Template.store(BUCKET_NAME, objectKey, file.getBytes());
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file to S3", e);
        }
        
        // Create Image metadata for DynamoDB
        Image image = new Image();
        image.setId(imageId);
        image.setObjectPath(objectKey);
        image.setObjectSize(String.valueOf(file.getSize()));
        image.setTimeAdded(LocalDateTime.now());
        image.setTimeUpdated(LocalDateTime.now());
        image.setStatus(Status.ACTIVE);
        
        // Save metadata to DynamoDB
        dynamoDbTemplate.save(image);
        return image;
    }

    public Image getById(UUID id) {
        Key key = Key.builder().partitionValue(id.toString()).build();
        return dynamoDbTemplate.load(key, Image.class);
    }

    public void deleteById(UUID id) {
        Key key = Key.builder().partitionValue(id.toString()).build();
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