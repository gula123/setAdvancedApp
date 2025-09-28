package com.example.demo;

import org.instancio.Instancio;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import software.amazon.awssdk.enhanced.dynamodb.Key;

import com.example.demo.config.TestcontainersConfiguration;
import com.example.demo.model.Image;
import com.example.demo.model.User;
import com.example.demo.service.ImageService;

import io.awspring.cloud.dynamodb.DynamoDbTemplate;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class DemoApplicationTests {

  @Autowired
  private ImageService imageService;

  @Autowired
  private DynamoDbTemplate dynamoDbTemplate;

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
void createAndRetrieveImageByLabel() {
  Set<String> label = Set.of("test-label");
  Image image = new Image();
  image.setId(UUID.randomUUID()); // Ensure id is set
  image.setLabels(label);

  imageService.create(image);

  List<Image> retrievedImages = imageService.searchByLabel("test-label");

  assertThat(retrievedImages.get(0))
      .isNotNull()
      .usingRecursiveComparison()
      .isEqualTo(image);
}

}
