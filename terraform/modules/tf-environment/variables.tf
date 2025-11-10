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

variable "vpc_cidr_third_octet" {
  type        = number
  description = "Third octet for VPC CIDR (e.g., 1 for 10.1.0.0/16, 2 for 10.2.0.0/16)"
  default     = 1
}