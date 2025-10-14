package com.example.demo.service;

import com.example.demo.model.Image;
import com.example.demo.model.Status;
import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import io.awspring.cloud.s3.S3Template;
import org.springframework.beans.factory.annotation.Value;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.multipart.MultipartFile;

import software.amazon.awssdk.enhanced.dynamodb.Expression;
import software.amazon.awssdk.enhanced.dynamodb.Key;
import software.amazon.awssdk.enhanced.dynamodb.model.ScanEnhancedRequest;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.io.IOException;
import java.net.URLConnection;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class ImageService {

    private final DynamoDbTemplate dynamoDbTemplate;
    private final S3Template s3Template;
    private final S3Client s3Client;
    
    @Value("${app.s3.bucket-name}")
    private String bucketName;

    @Autowired
    public ImageService(DynamoDbTemplate dynamoDbTemplate, S3Template s3Template, S3Client s3Client) {
        this.dynamoDbTemplate = dynamoDbTemplate;
        this.s3Template = s3Template;
        this.s3Client = s3Client;
    }

    public Image create(MultipartFile file) throws IOException {
        // Generate unique ID for the image
        UUID imageId = UUID.randomUUID();
        String objectKey = "images/" + imageId.toString() + "_" + file.getOriginalFilename();
        
        // Ensure bucket exists
        try {
            if (!s3Template.bucketExists(bucketName)) {
                s3Template.createBucket(bucketName);
            }
        } catch (software.amazon.awssdk.services.s3.model.S3Exception e) {
            if (e.statusCode() == 403) {
                throw new RuntimeException("AWS S3 access denied. Please check your AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) and bucket permissions for bucket: " + bucketName, e);
            } else if (e.statusCode() == 404) {
                throw new RuntimeException("S3 bucket not found: " + bucketName + ". Please create the bucket or check the bucket name configuration.", e);
            } else {
                throw new RuntimeException("Failed to access S3 bucket: " + bucketName + ". Error: " + e.getMessage(), e);
            }
        }
        
        // Upload file to S3 using direct S3Client to avoid serialization issues
        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .contentType(file.getContentType())
                .build();
            
            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(file.getBytes()));
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file to S3", e);
        }
        
        // Create Image metadata for DynamoDB
        Image image = new Image();
        image.setId(imageId.toString());
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
        String idString = id.toString();
        System.out.println("Looking for image with ID: " + idString);
        
        try {
            // Since we have a composite key (id + objectPath), we need to query by partition key
            // and get the first match (assuming one image per ID)
            Expression expression = Expression.builder()
                .expression("#id = :id")
                .putExpressionName("#id", "id")
                .putExpressionValue(":id", AttributeValue.builder().s(idString).build())
                .build();

            ScanEnhancedRequest scanRequest = ScanEnhancedRequest
                .builder()
                .filterExpression(expression)
                .limit(1)
                .build();

            return dynamoDbTemplate.scan(scanRequest, Image.class)
                .stream()
                .flatMap(page -> page.items().stream())
                .findFirst()
                .orElse(null);
        } catch (Exception e) {
            System.out.println("DynamoDB Error: " + e.getMessage());
            throw e;
        }
    }

    public void deleteById(UUID id) {
        Image image = getById(id);
        if (image != null) {
            try {
                // Delete file from S3 first
                s3Client.deleteObject(builder -> builder
                    .bucket(bucketName)
                    .key(image.getObjectPath())
                );
                
                // Then delete metadata from DynamoDB
                Key key = Key.builder()
                    .partitionValue(id.toString())
                    .sortValue(image.getObjectPath())
                    .build();
                dynamoDbTemplate.delete(key, Image.class);
            } catch (Exception e) {
                throw new RuntimeException("Failed to delete image: " + e.getMessage(), e);
            }
        }
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

    public byte[] downloadImageFile(UUID id) {
        // First get the image metadata to find the S3 object path
        Image image = getById(id);
        if (image == null) {
            throw new RuntimeException("Image not found with ID: " + id);
        }

        try {
            // Download the file from S3
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(image.getObjectPath())
                .build();
            
            return s3Client.getObject(getObjectRequest).readAllBytes();
        } catch (Exception e) {
            throw new RuntimeException("Failed to download image from S3: " + e.getMessage(), e);
        }
    }

    public String getImageContentType(UUID id) {
        Image image = getById(id);
        if (image == null) {
            return null;
        }
        
        String objectPath = image.getObjectPath();
        String contentType = URLConnection.guessContentTypeFromName(objectPath);
        
        return contentType != null ? contentType : "application/octet-stream";
    }
    
    public String getFileExtensionFromContentType(String contentType) {
        if (contentType == null) return "";
        
        return switch (contentType.toLowerCase()) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/gif" -> ".gif";
            case "image/webp" -> ".webp";
            default -> "";
        };
    }
}