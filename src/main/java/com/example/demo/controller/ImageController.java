package com.example.demo.controller;

import com.example.demo.config.UploadConfig;
import com.example.demo.model.Image;
import com.example.demo.service.ImageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/image")
public class ImageController {

    private final ImageService imageService;
    private final UploadConfig uploadConfig;

    @Autowired
    public ImageController(ImageService imageService, UploadConfig uploadConfig) {
        this.imageService = imageService;
        this.uploadConfig = uploadConfig;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Image> uploadImage(@RequestParam("file") MultipartFile file) {
        // Validate that the file is an image
        if (!isValidImageFile(file)) {
            return ResponseEntity.badRequest().build();
        }
        
        try {
            Image created = imageService.create(file);
            return ResponseEntity.ok(created);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }
    
    private boolean isValidImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return false;
        }
        
        String contentType = file.getContentType();
        if (contentType == null) {
            return false;
        }
        
        // Check if content type is in the configured supported image types
        return uploadConfig.getSupportedImageTypes().contains(contentType);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Object> getImage(@PathVariable UUID id) {
        try {
            Image image = imageService.getById(id);
            if (image == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(image);
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body("Error: " + e.getMessage() + " | Cause: " + (e.getCause() != null ? e.getCause().getMessage() : "none"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteImage(@PathVariable UUID id) {
        imageService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/")
    public ResponseEntity<List<Image>> searchByLabel(@RequestParam String label) {
        List<Image> images = imageService.searchByLabel(label);
        return ResponseEntity.ok(images);
    }

    @GetMapping("/file/{id}")
    public ResponseEntity<byte[]> downloadImageFile(@PathVariable UUID id) {
        try {
            byte[] imageData = imageService.downloadImageFile(id);
            String contentType = imageService.getImageContentType(id);
            
            // Get file extension from content type
            String fileExtension = imageService.getFileExtensionFromContentType(contentType);
            String filename = "image-" + id + fileExtension;
            
            return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                .body(imageData);
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.internalServerError().build();
        }
    }
}
