package com.example.demo.unit.controller;

import com.example.demo.config.UploadConfig;
import com.example.demo.controller.ImageController;
import com.example.demo.model.Image;
import com.example.demo.model.Status;
import com.example.demo.service.ImageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ImageControllerTest {

    @Mock
    private ImageService imageService;

    @Mock
    private UploadConfig uploadConfig;

    @InjectMocks
    private ImageController imageController;

    @BeforeEach
    void setUp() {
        lenient().when(uploadConfig.getSupportedImageTypes()).thenReturn(
            Arrays.asList("image/jpeg", "image/png", "image/gif", "image/webp")
        );
    }

    @Test
    void testUploadImage_Success() {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.jpg",
            "image/jpeg",
            "test image content".getBytes()
        );

        Image expectedImage = new Image();
        expectedImage.setId(UUID.randomUUID().toString());
        expectedImage.setObjectPath("images/test.jpg");
        expectedImage.setStatus(Status.ACTIVE);

        try {
            when(imageService.create(any())).thenReturn(expectedImage);
        } catch (IOException e) {
            fail("Should not throw IOException in mock setup");
        }

        // Act
        ResponseEntity<Image> response = imageController.uploadImage(file);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(expectedImage.getId(), response.getBody().getId());
        assertEquals(expectedImage.getObjectPath(), response.getBody().getObjectPath());
        assertEquals(expectedImage.getStatus(), response.getBody().getStatus());
        try {
            verify(imageService).create(argThat(f -> 
                f.getOriginalFilename().equals("test.jpg") && 
                f.getContentType().equals("image/jpeg")));
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    @Test
    void testUploadImage_NullFile() {
        // Act
        ResponseEntity<Image> response = imageController.uploadImage(null);

        // Assert
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        try {
            verify(imageService, never()).create(any());
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    @Test
    void testUploadImage_EmptyFile() {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.jpg",
            "image/jpeg",
            new byte[0]
        );

        // Act
        ResponseEntity<Image> response = imageController.uploadImage(file);

        // Assert
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        try {
            verify(imageService, never()).create(any());
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    @Test
    void testUploadImage_InvalidContentType() {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.txt",
            "text/plain",
            "test content".getBytes()
        );

        // Act
        ResponseEntity<Image> response = imageController.uploadImage(file);

        // Assert
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        try {
            verify(imageService, never()).create(any());
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    @Test
    void testUploadImage_ServiceThrowsIOException() {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.jpg",
            "image/jpeg",
            "test content".getBytes()
        );

        try {
            when(imageService.create(any())).thenThrow(new IOException("S3 error"));
        } catch (IOException e) {
            fail("Should not throw IOException in mock setup");
        }

        // Act
        ResponseEntity<Image> response = imageController.uploadImage(file);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        try {
            verify(imageService).create(any());
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    @Test
    void testGetImage_Success() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        Image image = new Image();
        image.setId(imageId.toString());
        image.setObjectPath("images/test.jpg");
        image.setStatus(Status.ACTIVE);

        when(imageService.getById(imageId)).thenReturn(image);

        // Act
        ResponseEntity<Object> response = imageController.getImage(imageId);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody() instanceof Image);
        assertEquals(imageId.toString(), ((Image) response.getBody()).getId());
        verify(imageService).getById(imageId);
    }

    @Test
    void testGetImage_NotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        when(imageService.getById(imageId)).thenReturn(null);

        // Act
        ResponseEntity<Object> response = imageController.getImage(imageId);

        // Assert
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        verify(imageService).getById(imageId);
    }

    @Test
    void testDeleteImage_Success() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        doNothing().when(imageService).deleteById(imageId);

        // Act
        ResponseEntity<Void> response = imageController.deleteImage(imageId);

        // Assert
        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());
        verify(imageService).deleteById(imageId);
    }

    @Test
    void testSearchByLabel_Success() {
        // Arrange
        String label = "cat";
        List<Image> images = Arrays.asList(
            createTestImage("id1", "cat1.jpg"),
            createTestImage("id2", "cat2.jpg")
        );

        when(imageService.searchByLabel(label)).thenReturn(images);

        // Act
        ResponseEntity<List<Image>> response = imageController.searchByLabel(label);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(2, response.getBody().size());
        verify(imageService).searchByLabel(label);
    }

    @Test
    void testSearchByLabel_NoResults() {
        // Arrange
        String label = "dog";
        when(imageService.searchByLabel(label)).thenReturn(Collections.emptyList());

        // Act
        ResponseEntity<List<Image>> response = imageController.searchByLabel(label);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isEmpty());
        verify(imageService).searchByLabel(label);
    }

    @Test
    void testDownloadImageFile_Success() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        byte[] fileContent = "test content".getBytes();

        when(imageService.downloadImageFile(imageId)).thenReturn(fileContent);
        when(imageService.getImageContentType(imageId)).thenReturn("image/jpeg");
        when(imageService.getFileExtensionFromContentType("image/jpeg")).thenReturn(".jpg");

        // Act
        ResponseEntity<byte[]> response = imageController.downloadImageFile(imageId);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertArrayEquals(fileContent, response.getBody());
        verify(imageService).downloadImageFile(imageId);
        verify(imageService).getImageContentType(imageId);
    }

    @Test
    void testDownloadImageFile_NotFound() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        when(imageService.downloadImageFile(imageId))
            .thenThrow(new RuntimeException("Image not found with ID: " + imageId));

        // Act
        ResponseEntity<byte[]> response = imageController.downloadImageFile(imageId);

        // Assert
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        verify(imageService).downloadImageFile(imageId);
    }

    @Test
    void testDownloadImageFile_S3Error() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        when(imageService.downloadImageFile(imageId))
            .thenThrow(new RuntimeException("Failed to download image from S3"));

        // Act
        ResponseEntity<byte[]> response = imageController.downloadImageFile(imageId);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        verify(imageService).downloadImageFile(imageId);
    }

    @Test
    void testGetImage_ExceptionThrown() {
        // Arrange
        UUID imageId = UUID.randomUUID();
        RuntimeException testException = new RuntimeException("Database connection failed", 
            new IllegalStateException("Connection timeout"));
        when(imageService.getById(imageId)).thenThrow(testException);

        // Act
        ResponseEntity<Object> response = imageController.getImage(imageId);

        // Assert
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().toString().contains("Database connection failed"));
        assertTrue(response.getBody().toString().contains("Connection timeout"));
        verify(imageService).getById(imageId);
    }

    @Test
    void testUploadImage_NullContentType() {
        // Arrange
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.jpg",
            null,  // null content type
            "test image content".getBytes()
        );

        // Act
        ResponseEntity<Image> response = imageController.uploadImage(file);

        // Assert
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        try {
            verify(imageService, never()).create(any());
        } catch (IOException e) {
            fail("Should not throw IOException in verify");
        }
    }

    // Helper method to create test images
    private Image createTestImage(String id, String filename) {
        Image image = new Image();
        image.setId(id);
        image.setObjectPath("images/" + filename);
        image.setObjectSize("1024");
        image.setStatus(Status.ACTIVE);
        image.setLabels(new HashSet<>());
        return image;
    }
}
