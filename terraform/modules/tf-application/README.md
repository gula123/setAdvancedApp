# tf-application Module

This module creates the non-persistent infrastructure components for the image recognition application.

## Resources Created

- **Lambda Function**: Processes images from SQS queue and runs image recognition
- **Application Load Balancer**: Distributes traffic to ECS tasks
- **ECS Cluster**: Hosts the containerized application
- **ECS Service**: Manages application instances
- **IAM Roles**: Execution and task roles for Lambda and ECS
- **CloudWatch Log Group**: Stores application logs

## Usage

```terraform
module "application" {
  source = "../modules/tf-application"
  
  s3_bucket_name      = module.environment.s3_bucket_name
  dynamodb_table_name = module.environment.dynamodb_table_name
  subnet_ids          = module.environment.default_subnet_ids
  vpc_id              = module.environment.default_vpc_id
  region_name         = module.environment.default_region_name
  sqs_queue_arn       = module.environment.sqs_queue_arn
  sqs_queue_url       = module.environment.sqs_queue_url
  image_uri           = "your-ecr-repo-uri:latest"
  environment         = "dev"
}
```

## Variables

- `s3_bucket_name`: Name of the S3 bucket for images (required)
- `dynamodb_table_name`: Name of the DynamoDB table for results (required)
- `subnet_ids`: List of subnet IDs for deployment (required)
- `vpc_id`: VPC ID for deployment (required)
- `region_name`: AWS region name (required)
- `sqs_queue_arn`: ARN of the SQS queue (required)
- `sqs_queue_url`: URL of the SQS queue (required)
- `image_uri`: URI of the container image for ECS (required)
- `environment`: Environment name for tagging (default: "dev")
- `application_port`: Port on which the application runs (default: 8080)

## Outputs

- `load_balancer_dns_name`: DNS name of the load balancer
- `load_balancer_zone_id`: Zone ID of the load balancer
- `ecs_cluster_name`: Name of the ECS cluster
- `ecs_service_name`: Name of the ECS service
- `lambda_function_name`: Name of the Lambda function
- `lambda_function_arn`: ARN of the Lambda function

## Lambda Function

The Lambda function processes images uploaded to S3 by:
1. Receiving SQS messages triggered by S3 events
2. Using Amazon Rekognition to detect labels in images
3. Storing recognition results in DynamoDB

## ECS Application

The ECS service runs containerized applications that can:
- Access S3 bucket for image operations
- Read/write to DynamoDB table
- Scale automatically based on load