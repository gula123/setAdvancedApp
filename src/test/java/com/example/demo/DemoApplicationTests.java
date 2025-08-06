package com.example.demo;

import org.instancio.Instancio;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;
import software.amazon.awssdk.enhanced.dynamodb.Key;

import com.example.demo.config.TestcontainersConfiguration;
import com.example.demo.model.User;

import io.awspring.cloud.dynamodb.DynamoDbTemplate;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class DemoApplicationTests {

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

}
