package com.example.demo.controller;

import com.example.demo.model.Image;
import com.example.demo.service.ImageService;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    public ImageController(ImageService imageService) {
        this.imageService = imageService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Image> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            Image created = imageService.create(file);
            return ResponseEntity.ok(created);
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getImage(@PathVariable UUID id) {
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
}
