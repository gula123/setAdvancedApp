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
class ImageGetByIdControllerTest {

    private static final List<String> createdImageIds = new ArrayList<>();
    private static File testImageFile;

    @BeforeAll
    static void setUpClass() {
        // Load actual test image from resources
        ClassLoader classLoader = ImageGetByIdControllerTest.class.getClassLoader();
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
    void testGetImageById() {
        // Create image
        Response response = given()
            .multiPart("file", testImageFile, "image/jpeg")
        .when()
            .post();
        String imageId = response.jsonPath().getString("id");
        createdImageIds.add(imageId);

        // Get by id
        given()
            .pathParam("id", imageId)
        .when()
            .get("/{id}")
        .then()
            .statusCode(200)
            .body("id", equalTo(imageId));
    }

    @Test
    @Order(2)
    void testGetImageByNonExistentId() {
        String nonExistentId = UUID.randomUUID().toString();
        given()
            .pathParam("id", nonExistentId)
        .when()
            .get("/{id}")
        .then()
            .statusCode(404);
    }
}
