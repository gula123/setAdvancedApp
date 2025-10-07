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
class ImageSearchByLabelControllerTest {

    private static final List<String> createdImageIds = new ArrayList<>();
    private static File testImageFile;

    @BeforeAll
    static void setUpClass() {
        // Load actual test image from resources
        ClassLoader classLoader = ImageSearchByLabelControllerTest.class.getClassLoader();
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
    void testSearchByLabel() throws InterruptedException {
        // Create image
        Response response = given()
            .multiPart("file", testImageFile, "image/jpeg")
        .when()
            .post();
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

        Assertions.assertNotNull(labels, "Labels should not be null after polling");
        Assertions.assertFalse(labels.isEmpty(), "Labels should not be empty after polling");
        String labelToSearch = labels.get(0);

        // Search by the actual label
        given()
            .queryParam("label", labelToSearch)
        .when()
            .get("/")
        .then()
            .statusCode(200)
            .body("labels.flatten()", hasItem(labelToSearch));
    }

    @Test
    @Order(2)
    void testSearchByWrongParameterKey() {
        // Test with wrong parameter key (should return 400 Bad Request)
        given()
            .queryParam("wrongParam", "somevalue")
        .when()
            .get("/")
        .then()
            .statusCode(400);
    }

    @Test
    @Order(3)
    void testSearchByNonExistentLabel() {
        // Test with a label that doesn't exist in any image
        String nonExistentLabel = "nonexistentlabel12345";
        
        given()
            .queryParam("label", nonExistentLabel)
        .when()
            .get("/")
        .then()
            .statusCode(200)
            .body("size()", equalTo(0)); // Should return empty array
    }
}
