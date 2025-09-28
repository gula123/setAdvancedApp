package com.example.demo;

import org.instancio.Instancio;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

import java.io.IOException;

import software.amazon.awssdk.enhanced.dynamodb.Key;

import com.example.demo.config.TestcontainersConfiguration;
import com.example.demo.model.Image;
import com.example.demo.model.User;
import com.example.demo.service.ImageService;

import io.awspring.cloud.dynamodb.DynamoDbTemplate;
import io.awspring.cloud.s3.S3Template;
import io.awspring.cloud.s3.S3Resource;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class DemoApplicationTests {

  @Autowired
  private ImageService imageService;

  @Autowired
  private DynamoDbTemplate dynamoDbTemplate;

  @Autowired
  private S3Template s3Template;

  @Test
  void createUser() {
    User user = Instancio.create(User.class);

    dynamoDbTemplate.save(user);

    dynamoDbTemplate.save(user);

    Key partitionKey = Key.builder().partitionValue(user.getId().toString()).build();
    User retrievedUser = dynamoDbTemplate.load(partitionKey, User.class);
    assertThat(retrievedUser)
        .isNotNull()
        .usingRecursiveComparison()
        .isEqualTo(user);
  }

  @Test
  void createAndRetrieveImageById() throws IOException {
    org.springframework.mock.web.MockMultipartFile multipartFile =
        new org.springframework.mock.web.MockMultipartFile(
            "file", "test.jpg", "image/jpeg", "dummy image content".getBytes()
        );

    Image createdImage = imageService.create(multipartFile);

    Image retrievedImage = imageService.getById(createdImage.getId());

    assertThat(retrievedImage)
        .isNotNull()
        .usingRecursiveComparison()
        .isEqualTo(createdImage);
  }

  @Test
  void testS3Operations() {
    s3Template.createBucket("test-bucket");

    s3Template.store("test-bucket", "test-key", "Hello S3!".getBytes());

    S3Resource resource = s3Template.download("test-bucket", "test-key");

    assertThat(resource).isNotNull();
  }

}
