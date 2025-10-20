# tf-environment Module

This module creates the persistent infrastructure components for the image recognition application.

## Resources Created

- **S3 Bucket**: Stores uploaded images with public read access
- **DynamoDB Table**: Stores image recognition results
- **SNS Topic**: Receives notifications when new images are uploaded
- **SQS Queue**: Queues image processing requests for Lambda
- **VPC Endpoints**: Secure connectivity to AWS services
- **Default Subnets**: Network infrastructure for application deployment

## Usage

```terraform
module "environment" {
  source = "../modules/tf-environment"

  bucket_name          = "my-unique-bucket-name"
  sns_name            = "image-notifications"
  sqs_name            = "image-processing"
  dynamodb_table_name = "recognition-results"
  environment         = "dev"
}
```

## Variables

- `bucket_name`: Name of the S3 bucket (default: "s3-image-bucket")
- `sns_name`: Name of the SNS topic (default: "image-notification-topic")
- `sqs_name`: Name of the SQS queue (default: "image-processing-queue")
- `dynamodb_table_name`: Name of the DynamoDB table (default: "image-recognition-results")
- `environment`: Environment name for tagging (default: "dev")

## Outputs

- `s3_bucket_name`: Name of the created S3 bucket
- `dynamodb_table_name`: Name of the created DynamoDB table
- `default_subnet_ids`: IDs of the default subnets
- `default_vpc_id`: ID of the default VPC
- `default_region_name`: Current AWS region name
- `sns_topic_arn`: ARN of the SNS topic
- `sqs_queue_arn`: ARN of the SQS queue
- `sqs_queue_url`: URL of the SQS queue