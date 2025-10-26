output "s3_bucket_name" {
  value       = aws_s3_bucket.image_bucket.bucket
  description = "Name of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.image_recognition_results.name
  description = "Name of the DynamoDB table"
}

output "default_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs of the private subnets"
}

output "default_vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the VPC"
}

output "default_region_name" {
  value       = data.aws_region.current.name
  description = "Name of the current AWS region"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.image_notification.arn
  description = "ARN of the SNS topic"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.image_processing_queue.arn
  description = "ARN of the SQS queue"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.image_processing_queue.url
  description = "URL of the SQS queue"
}

output "s3_kms_key_arn" {
  value       = aws_kms_key.s3_key.arn
  description = "ARN of the S3 KMS key"
}

output "dynamodb_kms_key_arn" {
  value       = aws_kms_key.dynamodb_key.arn
  description = "ARN of the DynamoDB KMS key"
}

output "sns_kms_key_arn" {
  value       = aws_kms_key.sns_key.arn
  description = "ARN of the SNS KMS key"
}

output "sqs_kms_key_arn" {
  value       = aws_kms_key.sqs_key.arn
  description = "ARN of the SQS KMS key"
}