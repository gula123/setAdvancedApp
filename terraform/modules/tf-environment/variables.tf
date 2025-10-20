variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
  default     = "s3-image-bucket"
}

variable "sns_name" {
  type        = string
  description = "Name of the SNS topic"
  default     = "image-notification-topic"
}

variable "sqs_name" {
  type        = string
  description = "Name of the SQS queue"
  default     = "image-processing-queue"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table"
  default     = "image-recognition-results"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, qa, prod)"
  default     = "dev"
}