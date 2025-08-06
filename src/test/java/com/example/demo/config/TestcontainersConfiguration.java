package com.example.demo.config;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.utility.DockerImageName;
import org.testcontainers.utility.MountableFile;

@TestConfiguration(proxyBeanMethods = false)
public
class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    LocalStackContainer localStackContainer() {
        System.out.println("Copying init-dynamodb-table.sh to LocalStack...");
        return new LocalStackContainer(DockerImageName.parse("localstack/localstack:4.3.0"))
          .withServices(LocalStackContainer.Service.DYNAMODB)
          .withCopyFileToContainer(
            MountableFile.forClasspathResource("init-dynamodb-table.sh", 0744),
            "/etc/localstack/init/ready.d/init-dynamodb-table.sh"
          )
          .waitingFor(Wait.forLogMessage(".*Executed init-dynamodb-table.sh.*", 1));
    }
}