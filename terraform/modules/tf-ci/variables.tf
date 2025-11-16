variable "environment" {
  type        = string
  description = "Environment name (ci)"
  default     = "ci"
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

variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-north-1"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "setadvanced"
}