package com.example.demo.controller;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.Assertions;

import java.io.File;
import java.util.ArrayList;
import java.util.List;


import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ImageUploadControllerTest {

    private static final List<String> createdImageIds = new ArrayList<>();
    private static File testImageFile;

    @BeforeAll
    static void setUpClass() {
        // Load actual test image from resources
        ClassLoader classLoader = ImageUploadControllerTest.class.getClassLoader();
        java.net.URL resource = classLoader.getResource("test-images/test-image.jpg");
        if (resource == null) {
            throw new RuntimeException("Test image not found at src/test/resources/test-images/test-image.jpg");
        }
        testImageFile = new File(resource.getFile());
    }

    @BeforeEach
    void setUp() {
        String baseUri = System.getenv().getOrDefault("TEST_BASE_URI", "http://localhost:8080");
        RestAssured.baseURI = baseUri;
        RestAssured.basePath = "/image";
    }



    @AfterEach
    void cleanUp() {
        createdImageIds.forEach(id -> {
            try {
                given().pathParam("id", id).delete("/{id}");
            } catch (Exception ignored) {
                // Ignore cleanup errors during test teardown
            }
        });
        createdImageIds.clear();
    }

    @Test
    @Order(1)
    void testCreateImage() throws InterruptedException {
        Response response = given()
            .multiPart("file", testImageFile, "image/jpeg")
        .when()
            .post()
        .then()
            .statusCode(200)
            .body("id", notNullValue())
            .body("objectPath", notNullValue())
            .extract().response();
        String imageId = response.jsonPath().getString("id");
        createdImageIds.add(imageId);

        // Wait and poll for labels to be assigned (max 30s, poll every 3s)
        List<String> labels = null;
        int maxAttempts = 10;
        for (int attempt = 0; attempt < maxAttempts; attempt++) {
            Response getResponse = given()
                .pathParam("id", imageId)
            .when()
                .get("/{id}");
            labels = getResponse.jsonPath().getList("labels", String.class);
            if (labels != null && !labels.isEmpty()) {
                break;
            }
            Thread.sleep(3000); // Wait 3 seconds before retry
        }

        Assertions.assertNotNull(labels, "Labels should be assigned to uploaded image after processing");
        Assertions.assertFalse(labels.isEmpty(), "At least one label should be assigned to the image");
    }

    @Test
    @Order(2)
    void testCreateImageMissingFile() {
        given()
        .when()
            .post()
        .then()
            .statusCode(415); // Missing multipart file returns 415 Unsupported Media Type
    }

    @Test
    @Order(3)
    void testUploadNonImageFile() throws Exception {
        // Create a temporary text file
        File txtFile = File.createTempFile("test-document", ".txt");
        try (java.io.FileWriter writer = new java.io.FileWriter(txtFile)) {
            writer.write("This is a test text file, not an image!");
        }

        try {
            given()
                .multiPart("file", txtFile, "text/plain")
            .when()
                .post()
            .then()
                .statusCode(400);
        } finally {
            // Clean up the temporary file
            if (txtFile.exists()) {
                txtFile.delete();
            }
        }
    }
}
