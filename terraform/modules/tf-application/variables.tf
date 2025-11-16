variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for images"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for results"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ECS tasks"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "region_name" {
  type        = string
  description = "AWS region name"
}

variable "image_uri" {
  type        = string
  description = "URI of the container image for ECS"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, qa, prod)"
  default     = "dev"
}

variable "application_port" {
  type        = number
  description = "Port on which the application runs"
  default     = 8080
}

variable "domain_name" {
  type        = string
  description = "Domain name for SSL certificate (optional)"
  default     = ""
}

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS with SSL certificate"
  default     = true
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue"
}

variable "sqs_queue_url" {
  type        = string
  description = "URL of the SQS queue"
}

variable "sqs_kms_key_arn" {
  type        = string
  description = "ARN of the SQS KMS key"
  default     = ""
}

variable "dynamodb_kms_key_arn" {
  type        = string
  description = "ARN of the DynamoDB KMS key"
  default     = ""
}

variable "s3_kms_key_arn" {
  type        = string
  description = "ARN of the S3 KMS key"
  default     = ""
}

variable "enable_blue_green_deployment" {
  type        = bool
  description = "Enable blue-green deployment with CodeDeploy"
  default     = false
}