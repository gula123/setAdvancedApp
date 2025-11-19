package com.example.demo.unit.service;

import com.example.demo.model.Image;
import com.example.demo.model.Status;
import com.example.demo.service.ImageService;
import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import io.awspring.cloud.s3.S3Template;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ImageServiceTest {

    @Mock
    private DynamoDbTemplate dynamoDbTemplate;

    @Mock
    private S3Template s3Template;

    @Mock
    private S3Client s3Client;

    @Mock
    private MultipartFile multipartFile;

    @InjectMocks
    private ImageService imageService;

    private final String testBucketName = "test-bucket";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(imageService, "bucketName", testBucketName);
    }

    @Test
    void testCreate_Success() throws IOException {
        // Arrange
        String fileName = "test-image.jpg";
        byte[] fileContent = "test content".getBytes();
        
        when(multipartFile.getOriginalFilename()).thenReturn(fileName);
        when(multipartFile.getBytes()).thenReturn(fileContent);
        when(multipartFile.getSize()).thenReturn((long) fileContent.length);
        when(multipartFile.getContentType()).thenReturn("image/jpeg");
        
        when(s3Template.bucketExists(testBucketName)).thenReturn(true);
        when(dynamoDbTemplate.save(any(Image.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Image result = imageService.create(multipartFile);

        // Assert
        assertNotNull(result);
        assertNotNull(result.getId());
        assertTrue(result.getObjectPath().contains("images/"));
        assertTrue(result.getObjectPath().contains(fileName));
        assertEquals(String.valueOf(fileContent.length), result.getObjectSize());
        assertEquals(Status.ACTIVE, result.getStatus());
        assertNotNull(result.getTimeAdded());

        verify(s3Client).putObject(any(PutObjectRequest.class), any(RequestBody.class));
        verify(dynamoDbTemplate).save(any(Image.class));
    }

    @Test
    void testCreate_ThrowsIOException() throws IOException {
        // Arrange
        when(multipartFile.getOriginalFilename()).thenReturn("test.jpg");
        when(multipartFile.getContentType()).thenReturn("image/jpeg");
        when(s3Template.bucketExists(testBucketName)).thenReturn(true);
        when(multipartFile.getBytes()).thenThrow(new IOException("Test exception"));

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> imageService.create(multipartFile));
        assertTrue(exception.getMessage().contains("Failed to upload file to S3"));
        verify(dynamoDbTemplate, never()).save(any(Image.class));
    }

    @Test
    void testGetFileExtensionFromContentType() {
        // Test JPEG
        assertEquals(".jpg", imageService.getFileExtensionFromContentType("image/jpeg"));
        assertEquals(".jpg", imageService.getFileExtensionFromContentType("IMAGE/JPEG"));
        
        // Test PNG
        assertEquals(".png", imageService.getFileExtensionFromContentType("image/png"));
        
        // Test GIF
        assertEquals(".gif", imageService.getFileExtensionFromContentType("image/gif"));
        
        // Test WebP
        assertEquals(".webp", imageService.getFileExtensionFromContentType("image/webp"));
        
        // Test unknown
        assertEquals("", imageService.getFileExtensionFromContentType("image/unknown"));
        assertEquals("", imageService.getFileExtensionFromContentType(null));
    }

    @Test
    void testDeleteById_ImageExists() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image existingImage = new Image();
        existingImage.setId(imageId.toString());
        existingImage.setObjectPath("images/test.jpg");
        
        // Mock the scan to return the image  
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.of(
            software.amazon.awssdk.enhanced.dynamodb.model.Page.create(java.util.List.of(existingImage))
        ));

        // Act
        imageService.deleteById(imageId);

        // Assert
        verify(dynamoDbTemplate).delete(any(), eq(Image.class));
    }

    @Test
    void testDeleteById_ImageNotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.empty());

        // Act
        imageService.deleteById(imageId);

        // Assert - should not attempt to delete if image doesn't exist
        verify(dynamoDbTemplate, never()).delete(any(), eq(Image.class));
    }

    @Test
    void testGetById_Success() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image expectedImage = new Image();
        expectedImage.setId(imageId.toString());
        expectedImage.setObjectPath("images/test.jpg");
        expectedImage.setStatus(Status.ACTIVE);
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.of(
            software.amazon.awssdk.enhanced.dynamodb.model.Page.create(java.util.List.of(expectedImage))
        ));

        // Act
        Image result = imageService.getById(imageId);

        // Assert
        assertNotNull(result);
        assertEquals(imageId.toString(), result.getId());
        assertEquals("images/test.jpg", result.getObjectPath());
    }

    @Test
    void testGetById_NotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.empty());

        // Act
        Image result = imageService.getById(imageId);

        // Assert
        assertNull(result);
    }

    @Test
    void testSearchByLabel_WithResults() {
        // Arrange
        String label = "cat";
        Image image1 = new Image();
        image1.setId(UUID.randomUUID().toString());
        image1.setLabels(java.util.Set.of("cat", "animal"));
        
        Image image2 = new Image();
        image2.setId(UUID.randomUUID().toString());
        image2.setLabels(java.util.Set.of("cat", "pet"));
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.of(
            software.amazon.awssdk.enhanced.dynamodb.model.Page.create(java.util.List.of(image1, image2))
        ));

        // Act
        List<Image> result = imageService.searchByLabel(label);

        // Assert
        assertNotNull(result);
        assertEquals(2, result.size());
    }

    @Test
    void testDownloadImageFile_Success() throws Exception {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image image = new Image();
        image.setId(imageId.toString());
        image.setObjectPath("images/test.jpg");
        
        byte[] expectedBytes = "image content".getBytes();
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.of(
            software.amazon.awssdk.enhanced.dynamodb.model.Page.create(java.util.List.of(image))
        ));
        
        @SuppressWarnings("unchecked")
        ResponseInputStream<GetObjectResponse> mockInputStream = 
            mock(ResponseInputStream.class);
        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(mockInputStream);
        when(mockInputStream.readAllBytes()).thenReturn(expectedBytes);

        // Act
        byte[] result = imageService.downloadImageFile(imageId);

        // Assert
        assertNotNull(result);
        assertArrayEquals(expectedBytes, result);
    }

    @Test
    void testDownloadImageFile_ImageNotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.empty());

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, 
            () -> imageService.downloadImageFile(imageId));
        assertTrue(exception.getMessage().contains("Image not found"));
    }

    @Test
    void testGetImageContentType_Success() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image image = new Image();
        image.setId(imageId.toString());
        image.setObjectPath("images/test.jpg");
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.of(
            software.amazon.awssdk.enhanced.dynamodb.model.Page.create(java.util.List.of(image))
        ));

        // Act
        String result = imageService.getImageContentType(imageId);

        // Assert
        assertNotNull(result);
        assertTrue(result.equals("image/jpeg") || result.equals("application/octet-stream"));
    }

    @Test
    void testGetImageContentType_ImageNotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        
        @SuppressWarnings("unchecked")
        software.amazon.awssdk.enhanced.dynamodb.model.PageIterable<Image> mockPageIterable = 
            mock(software.amazon.awssdk.enhanced.dynamodb.model.PageIterable.class);
        
        when(dynamoDbTemplate.scan(any(), eq(Image.class))).thenReturn(mockPageIterable);
        when(mockPageIterable.stream()).thenReturn(java.util.stream.Stream.empty());

        // Act
        String result = imageService.getImageContentType(imageId);

        // Assert
        assertNull(result);
    }

    @Test
    void testCreate_S3AccessDenied() {
        // Arrange
        software.amazon.awssdk.services.s3.model.S3Exception s3Exception = 
            (software.amazon.awssdk.services.s3.model.S3Exception) software.amazon.awssdk.services.s3.model.S3Exception
                .builder()
                .statusCode(403)
                .message("Access Denied")
                .build();
        
        when(s3Template.bucketExists(testBucketName)).thenThrow(s3Exception);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, 
            () -> imageService.create(multipartFile));
        assertTrue(exception.getMessage().contains("AWS S3 access denied"));
        verify(s3Template).bucketExists(testBucketName);
        verify(dynamoDbTemplate, never()).save(any());
    }

    @Test
    void testCreate_S3BucketNotFound() {
        // Arrange
        software.amazon.awssdk.services.s3.model.S3Exception s3Exception = 
            (software.amazon.awssdk.services.s3.model.S3Exception) software.amazon.awssdk.services.s3.model.S3Exception
                .builder()
                .statusCode(404)
                .message("Bucket not found")
                .build();
        
        when(s3Template.bucketExists(testBucketName)).thenThrow(s3Exception);

        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, 
            () -> imageService.create(multipartFile));
        assertTrue(exception.getMessage().contains("S3 bucket not found"));
        verify(s3Template).bucketExists(testBucketName);
        verify(s3Client, never()).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }

    @Test
    void testCreate_BucketDoesNotExist_CreatesBucket() throws IOException {
        // Arrange
        String fileName = "test-image.jpg";
        byte[] fileContent = "test content".getBytes();
        
        when(multipartFile.getOriginalFilename()).thenReturn(fileName);
        when(multipartFile.getBytes()).thenReturn(fileContent);
        when(multipartFile.getSize()).thenReturn((long) fileContent.length);
        when(multipartFile.getContentType()).thenReturn("image/jpeg");
        
        when(s3Template.bucketExists(testBucketName)).thenReturn(false);
        when(s3Template.createBucket(testBucketName)).thenReturn(null);
        when(dynamoDbTemplate.save(any(Image.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act
        Image result = imageService.create(multipartFile);

        // Assert
        assertNotNull(result);
        verify(s3Template).createBucket(testBucketName);
        verify(s3Client).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }
}
