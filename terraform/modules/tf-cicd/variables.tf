variable "environment" {
  type        = string
  description = "Environment name (dev, qa, prod)"
  default     = "dev"
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token"
  sensitive   = true
}

variable "github_branch" {
  type        = string
  description = "GitHub branch to monitor"
  default     = "main"
}

variable "ecr_repository_uri" {
  type        = string
  description = "ECR repository URI for container images"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name for deployment"
}

variable "ecs_service_name" {
  type        = string
  description = "ECS service name for deployment"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name for deployment"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket for lambda deployment artifacts"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "container_name" {
  type        = string
  description = "Container name in ECS task definition"
  default     = "app"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "setadvanced"
}

variable "target_group_name" {
  type        = string
  description = "ALB target group name for blue-green deployment"
  default     = ""
}

variable "blue_green_hook_lambda_name" {
  type        = string
  description = "Lambda function name for blue-green deployment hooks"
  default     = ""
}