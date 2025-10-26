variable "aws_region" {
  type        = string
  description = "AWS region for backend resources"
  default     = "eu-north-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Terraform state"
  default     = "setadvanced-terraform-state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for state locking"
  default     = "terraform-state-lock"
}