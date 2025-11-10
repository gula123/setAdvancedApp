package com.example.demo.infrastructure;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.boot.test.context.SpringBootTest;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.DescribeTableRequest;
import software.amazon.awssdk.services.dynamodb.model.DescribeTableResponse;
import software.amazon.awssdk.services.dynamodb.model.TableStatus;
import software.amazon.awssdk.services.elasticloadbalancingv2.ElasticLoadBalancingV2Client;
import software.amazon.awssdk.services.elasticloadbalancingv2.model.DescribeLoadBalancersRequest;
import software.amazon.awssdk.services.elasticloadbalancingv2.model.DescribeLoadBalancersResponse;
import software.amazon.awssdk.services.elasticloadbalancingv2.model.LoadBalancer;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sqs.SqsClient;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Configuration record for environment-specific infrastructure settings
 */
record InfrastructureConfig(
    String environment,
    String region,
    String s3BucketName,
    String dynamoDbTableName,
    String albName,
    String snsTopicName,
    String sqsQueueName
) {}

/**
 * Base infrastructure test class with common test logic
 * Environment-specific test classes should extend this and provide configuration via constructor
 */
@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class BaseInfrastructureTest {

    protected final InfrastructureConfig config;

    protected BaseInfrastructureTest(InfrastructureConfig config) {
        this.config = config;
    }

    @Test
    public void testS3BucketHealth() {
        try (S3Client s3Client = S3Client.builder()
                .region(Region.of(config.region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            s3Client.headBucket(HeadBucketRequest.builder()
                    .bucket(config.s3BucketName())
                    .build());
            
            System.out.println("✅ S3 Bucket '" + config.s3BucketName() + "' is accessible");
        } catch (Exception e) {
            System.err.println("Failed to validate S3 Bucket: " + e.getMessage());
            fail("S3 Bucket health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testDynamoDbTableHealth() {
        try (DynamoDbClient dynamoClient = DynamoDbClient.builder()
                .region(Region.of(config.region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            DescribeTableResponse response = dynamoClient.describeTable(
                    DescribeTableRequest.builder()
                            .tableName(config.dynamoDbTableName())
                            .build());
            
            assertEquals(TableStatus.ACTIVE, response.table().tableStatus(),
                    "DynamoDB table should be in ACTIVE status");
            
            System.out.println("✅ DynamoDB Table '" + config.dynamoDbTableName() + "' is active");
        } catch (Exception e) {
            System.err.println("Failed to validate DynamoDB Table: " + e.getMessage());
            fail("DynamoDB Table health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testLoadBalancerHealth() {
        try (ElasticLoadBalancingV2Client elbClient = ElasticLoadBalancingV2Client.builder()
                .region(Region.of(config.region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            DescribeLoadBalancersResponse response = elbClient.describeLoadBalancers(
                    DescribeLoadBalancersRequest.builder().build());
            
            LoadBalancer loadBalancer = response.loadBalancers().stream()
                    .filter(lb -> lb.loadBalancerName().equals(config.albName()))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException(config.environment().toUpperCase() + " Load Balancer not found"));
            
            assertEquals("active", loadBalancer.state().code().toString(),
                    "Load Balancer should be in active state");
            
            System.out.println("✅ Application Load Balancer '" + config.albName() + "' is active");
        } catch (Exception e) {
            System.err.println("Failed to validate Load Balancer: " + e.getMessage());
            fail("Load Balancer health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testSnsTopicHealth() {
        try (SnsClient snsClient = SnsClient.builder()
                .region(Region.of(config.region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            // List all topics and find our topic
            var listTopicsResponse = snsClient.listTopics();
            var topic = listTopicsResponse.topics().stream()
                    .filter(t -> t.topicArn().endsWith(":" + config.snsTopicName()))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("SNS Topic '" + config.snsTopicName() + "' not found"));
            
            // Verify topic is accessible by getting its attributes
            var response = snsClient.getTopicAttributes(software.amazon.awssdk.services.sns.model.GetTopicAttributesRequest.builder()
                    .topicArn(topic.topicArn())
                    .build());
            
            assertNotNull(response.attributes(), "SNS Topic attributes should not be null");
            assertFalse(response.attributes().isEmpty(), "SNS Topic should have attributes");
            
            System.out.println("✅ SNS Topic '" + config.snsTopicName() + "' is active and accessible");
        } catch (Exception e) {
            fail("❌ SNS Topic test failed: " + e.getMessage());
        }
    }

    @Test
    public void testSqsQueueHealth() {
        try (SqsClient sqsClient = SqsClient.builder()
                .region(Region.of(config.region()))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            // List all queues and find our queue
            var listQueuesResponse = sqsClient.listQueues();
            String queueUrl = listQueuesResponse.queueUrls().stream()
                    .filter(url -> url.endsWith("/" + config.sqsQueueName()))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("SQS Queue '" + config.sqsQueueName() + "' not found"));
            
            // Verify queue is accessible by getting its attributes
            var response = sqsClient.getQueueAttributes(software.amazon.awssdk.services.sqs.model.GetQueueAttributesRequest.builder()
                    .queueUrl(queueUrl)
                    .attributeNames(software.amazon.awssdk.services.sqs.model.QueueAttributeName.QUEUE_ARN)
                    .build());
            
            assertNotNull(response.attributes(), "SQS Queue attributes should not be null");
            assertFalse(response.attributes().isEmpty(), "SQS Queue should have attributes");
            
            // Check if queue has ARN (indicates it's properly created)
            assertTrue(response.attributes().containsKey(software.amazon.awssdk.services.sqs.model.QueueAttributeName.QUEUE_ARN), 
                      "SQS Queue should have an ARN");
            
            System.out.println("✅ SQS Queue '" + config.sqsQueueName() + "' is active and accessible");
        } catch (Exception e) {
            fail("❌ SQS Queue test failed: " + e.getMessage());
        }
    }
}