package com.example.demo.controller;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.*;


import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ImageFileDownloadControllerTest {

    private static final List<String> createdImageIds = new ArrayList<>();
    private static File testImageFile;

    @BeforeAll
    static void setUpClass() {
        // Load actual test image from resources
        ClassLoader classLoader = ImageFileDownloadControllerTest.class.getClassLoader();
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
    void testDownloadImageFile() {
        // Create image first
        Response createResponse = given()
            .multiPart("file", testImageFile, "image/jpeg")
        .when()
            .post();
        
        // Verify upload was successful
        createResponse.then().statusCode(200);
        String imageId = createResponse.jsonPath().getString("id");
        createdImageIds.add(imageId);
        
        System.out.println("Created image with ID: " + imageId);

        // Wait for AWS eventual consistency (increased time)
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // First check if image exists via regular GET
        Response getResponse = given()
            .pathParam("id", imageId)
        .when()
            .get("/file/{id}");
        
        System.out.println("GET /{id} response status: " + getResponse.getStatusCode());
        if (getResponse.getStatusCode() != 200) {
            System.out.println("GET /{id} response body: " + getResponse.getBody().asString());
        }

        // Download the file
        given()
            .pathParam("id", imageId)
        .when()
            .get("/file/{id}")
        .then()
            .statusCode(200)
            .contentType("image/jpeg")
            .header("Content-Disposition", containsString("inline"))
            .header("Content-Disposition", containsString("image-" + imageId))
            .body(notNullValue());
    }

    @Test
    @Order(2)
    void testDownloadNonExistentImageFile() {
        String nonExistentId = UUID.randomUUID().toString();
        
        given()
            .pathParam("id", nonExistentId)
        .when()
            .get("/file/{id}")
        .then()
            .statusCode(404);
    }

    @Test
    @Order(3)
    void testDownloadImageFileWithDifferentFormats() {
        // Test with PNG file from resources
        ClassLoader classLoader = ImageFileDownloadControllerTest.class.getClassLoader();
        java.net.URL pngResource = classLoader.getResource("test-images/test-image.png");
        
        if (pngResource != null) {
            File pngFile = new File(pngResource.getFile());
            
            Response createResponse = given()
                .multiPart("file", pngFile, "image/png")
            .when()
                .post();
            String imageId = createResponse.jsonPath().getString("id");
            createdImageIds.add(imageId);

            // Wait for AWS eventual consistency
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            // Download PNG file
            given()
                .pathParam("id", imageId)
            .when()
                .get("/file/{id}")
            .then()
                .statusCode(200)
                .contentType("image/png")
                .header("Content-Disposition", containsString("inline"));
        } else {
            // Skip PNG test if file not available
            System.out.println("PNG test file not found, skipping format test");
        }
    }

    @Test
    @Order(4)
    void testDownloadImageFileResponseSize() {
        // Create image
        Response createResponse = given()
            .multiPart("file", testImageFile, "image/jpeg")
        .when()
            .post();
        String imageId = createResponse.jsonPath().getString("id");
        createdImageIds.add(imageId);

        // Wait for AWS eventual consistency
        try {
            Thread.sleep(2000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // Download and verify response has content
        Response downloadResponse = given()
            .pathParam("id", imageId)
        .when()
            .get("/file/{id}")
        .then()
            .statusCode(200)
            .extract().response();

        // Verify response body is not empty
        byte[] responseBody = downloadResponse.getBody().asByteArray();
        assert responseBody.length > 0 : "Downloaded file should not be empty";
    }
}