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

variable "use_github_v2" {
  type        = bool
  description = "Use GitHub v2 (CodeStar Connections) with trigger filters instead of GitHub v1"
  default     = false
}

variable "github_connection_arn" {
  type        = string
  description = "Existing CodeStar Connection ARN (if use_github_v2 is true and connection already exists)"
  default     = ""
}

variable "github_trigger_branch_patterns" {
  type        = list(string)
  description = "Branch patterns for GitHub v2 triggers (e.g., ['release/**'])"
  default     = []
}

variable "enable_pr_validation" {
  type        = bool
  description = "Enable PR validation pipeline with Terraform static checks"
  default     = true
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
  description = "ALB target group name for blue-green deployment (blue)"
  default     = ""
}

variable "target_group_green_name" {
  type        = string
  description = "ALB target group name for blue-green deployment (green)"
  default     = ""
}

variable "blue_green_hook_lambda_name" {
  type        = string
  description = "Lambda function name for blue-green deployment hooks"
  default     = ""
}

variable "listener_arn" {
  type        = string
  description = "ALB listener ARN for blue-green deployment"
  default     = ""
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the target group for infrastructure tests"
  default     = ""
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the Application Load Balancer for infrastructure tests"
  default     = ""
}

variable "dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for image recognition results"
}