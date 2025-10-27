package com.example.demo.infrastructure;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
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
import software.amazon.awssdk.services.sns.model.GetTopicAttributesRequest;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueAttributesRequest;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Infrastructure test for PROD environment
 * Validates that all AWS services are properly deployed and running
 */
@SpringBootTest
@ActiveProfiles("prod")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class ProdInfrastructureTest {

    private static final String REGION = "eu-north-1";
    private static final String S3_BUCKET_NAME = "setadvanced-gula-prod";
    private static final String DYNAMODB_TABLE_NAME = "image-recognition-results-prod";
    private static final String ALB_NAME = "app-lb-prod";
    private static final String SNS_TOPIC_NAME = "s3-events-prod";
    private static final String SQS_QUEUE_NAME = "image-processing-queue-prod";

    @Test
    public void testS3BucketHealth() {
        try (S3Client s3Client = S3Client.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            s3Client.headBucket(HeadBucketRequest.builder()
                    .bucket(S3_BUCKET_NAME)
                    .build());
            
            System.out.println("✅ S3 Bucket '" + S3_BUCKET_NAME + "' is accessible");
        } catch (Exception e) {
            System.err.println("Failed to validate S3 Bucket: " + e.getMessage());
            fail("S3 Bucket health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testDynamoDbTableHealth() {
        try (DynamoDbClient dynamoClient = DynamoDbClient.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            DescribeTableResponse response = dynamoClient.describeTable(
                    DescribeTableRequest.builder()
                            .tableName(DYNAMODB_TABLE_NAME)
                            .build());
            
            assertEquals(TableStatus.ACTIVE, response.table().tableStatus(),
                    "DynamoDB table should be in ACTIVE status");
            
            System.out.println("✅ DynamoDB Table '" + DYNAMODB_TABLE_NAME + "' is active");
        } catch (Exception e) {
            System.err.println("Failed to validate DynamoDB Table: " + e.getMessage());
            fail("DynamoDB Table health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testLoadBalancerHealth() {
        try (ElasticLoadBalancingV2Client elbClient = ElasticLoadBalancingV2Client.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            DescribeLoadBalancersResponse response = elbClient.describeLoadBalancers(
                    DescribeLoadBalancersRequest.builder().build());
            
            LoadBalancer prodLoadBalancer = response.loadBalancers().stream()
                    .filter(lb -> lb.loadBalancerName().equals(ALB_NAME))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("PROD Load Balancer not found"));
            
            assertEquals("active", prodLoadBalancer.state().code().toString(),
                    "Load Balancer should be in active state");
            
            System.out.println("✅ Application Load Balancer '" + ALB_NAME + "' is active");
        } catch (Exception e) {
            System.err.println("Failed to validate Load Balancer: " + e.getMessage());
            fail("Load Balancer health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testSnsTopicHealth() {
        try (SnsClient snsClient = SnsClient.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            // List all topics and find our topic
            var listTopicsResponse = snsClient.listTopics();
            var prodTopic = listTopicsResponse.topics().stream()
                    .filter(topic -> topic.topicArn().endsWith(":" + SNS_TOPIC_NAME))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("SNS Topic '" + SNS_TOPIC_NAME + "' not found"));
            
            // Verify topic is accessible by getting its attributes
            var response = snsClient.getTopicAttributes(software.amazon.awssdk.services.sns.model.GetTopicAttributesRequest.builder()
                    .topicArn(prodTopic.topicArn())
                    .build());
            
            assertNotNull(response.attributes(), "SNS Topic attributes should not be null");
            assertFalse(response.attributes().isEmpty(), "SNS Topic should have attributes");
            
            System.out.println("✅ SNS Topic '" + SNS_TOPIC_NAME + "' is active and accessible");
        } catch (Exception e) {
            System.err.println("Failed to validate SNS Topic: " + e.getMessage());
            fail("SNS Topic health check failed: " + e.getMessage());
        }
    }

    @Test
    public void testSqsQueueHealth() {
        try (SqsClient sqsClient = SqsClient.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            // List all queues and find our queue
            var listQueuesResponse = sqsClient.listQueues();
            String queueUrl = listQueuesResponse.queueUrls().stream()
                    .filter(url -> url.endsWith("/" + SQS_QUEUE_NAME))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("SQS Queue '" + SQS_QUEUE_NAME + "' not found"));
            
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
            
            System.out.println("✅ SQS Queue '" + SQS_QUEUE_NAME + "' is active and accessible");
        } catch (Exception e) {
            System.err.println("Failed to validate SQS Queue: " + e.getMessage());
            fail("SQS Queue health check failed: " + e.getMessage());
        }
    }
}