output "s3_bucket_name" {
  value       = aws_s3_bucket.image_bucket.bucket
  description = "Name of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.image_recognition_results.name
  description = "Name of the DynamoDB table"
}

output "default_subnet_ids" {
  value       = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  description = "IDs of the default subnets"
}

output "default_vpc_id" {
  value       = data.aws_vpc.default.id
  description = "ID of the default VPC"
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