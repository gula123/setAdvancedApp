variable "github_token" {
  type        = string
  description = "GitHub personal access token for repository access"
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "ecr_repository_uri" {
  type        = string
  description = "ECR repository URI for container images"
  default     = "ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/set/setadvancedrepository"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name for lambda deployment artifacts"
  default     = "setadvanced-gula-qa"
}