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
 * Infrastructure test for QA environment
 * Validates that all AWS services are properly deployed and running
 */
@SpringBootTest
@ActiveProfiles("qa")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public class QaInfrastructureTest {

    private static final String REGION = "eu-north-1";
    private static final String S3_BUCKET_NAME = "setadvanced-gula-qa";
    private static final String DYNAMODB_TABLE_NAME = "image-recognition-results-qa";
    private static final String ALB_NAME = "app-lb-qa";
    private static final String SNS_TOPIC_ARN = "arn:aws:sns:eu-north-1:236292171120:s3-events-qa";
    private static final String SQS_QUEUE_URL = "https://sqs.eu-north-1.amazonaws.com/236292171120/image-processing-queue-qa";

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
            fail("❌ S3 Bucket test failed: " + e.getMessage());
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
            
            LoadBalancer qaLoadBalancer = response.loadBalancers().stream()
                    .filter(lb -> lb.loadBalancerName().equals(ALB_NAME))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("QA Load Balancer not found"));
            
            assertEquals("active", qaLoadBalancer.state().code().toString(),
                    "Load Balancer should be in active state");
            
            System.out.println("✅ Application Load Balancer '" + ALB_NAME + "' is active");
        }
    }

    @Test
    public void testSnsTopicHealth() {
        try (SnsClient snsClient = SnsClient.builder()
                .region(Region.of(REGION))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build()) {
            
            snsClient.getTopicAttributes(GetTopicAttributesRequest.builder()
                    .topicArn(SNS_TOPIC_ARN)
                    .build());
            System.out.println("✅ SNS Topic is accessible");
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
            
            sqsClient.getQueueAttributes(GetQueueAttributesRequest.builder()
                    .queueUrl(SQS_QUEUE_URL)
                    .build());
            
            System.out.println("✅ SQS Queue is accessible");
        } catch (Exception e) {
            System.err.println("Failed to validate SQS Queue: " + e.getMessage());
            fail("SQS Queue health check failed: " + e.getMessage());
        }
    }
}