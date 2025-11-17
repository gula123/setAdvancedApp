terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "eu-north-1"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get existing ECR repository
data "aws_ecr_repository" "app_repo" {
  name = "set/setadvancedrepository"
}

# Get existing ALB
data "aws_lb" "app_lb" {
  name = "app-lb-qa"
}

# Get existing target group
data "aws_lb_target_group" "app_tg" {
  name = "app-tg-qa"
}

# QA Environment CI/CD Pipeline
module "cicd" {
  source = "../modules/tf-cicd"

  # Environment Configuration
  environment = "qa"
  project_name = "setadvanced"

  # GitHub Configuration
  github_owner  = "gula123"
  github_repo   = "setAdvancedApp"
  github_branch = "release/1.0.0"  # Default branch for manual starts
  github_token  = var.github_token

  # GitHub v2 with trigger filters for release/* branches
  use_github_v2                  = true
  github_connection_arn          = "arn:aws:codeconnections:eu-north-1:236292171120:connection/64fa0a89-6176-4fb9-b25a-fa7ccd1ca8ab"
  github_trigger_branch_patterns = ["release/**"]

  # PR Validation - Disabled for QA (branch-based deployment)
  enable_pr_validation = false

  # AWS Configuration
  region     = "eu-north-1"
  account_id = data.aws_caller_identity.current.account_id

  # ECR Repository
  ecr_repository_uri = data.aws_ecr_repository.app_repo.repository_url

  # ECS Configuration
  ecs_cluster_name = "app-cluster-qa"
  ecs_service_name = "app-service-qa"
  container_name   = "app-container"

  # Lambda Configuration
  lambda_function_name = "image-processing-lambda-qa"

  # S3 Configuration
  s3_bucket_name      = "setadvanced-gula-qa"
  dynamodb_table_name = "image-recognition-results-qa"

  # Standard deployment configuration (no Blue-Green for QA)
  target_group_name = data.aws_lb_target_group.app_tg.name
  target_group_arn  = data.aws_lb_target_group.app_tg.arn
  alb_dns_name      = data.aws_lb.app_lb.dns_name
}
# Outputs
output "codepipeline_name" {
  value       = module.cicd.codepipeline_name
  description = "Name of the CodePipeline"
}

output "github_connection_arn" {
  value       = module.cicd.github_connection_arn
  description = "GitHub connection ARN (needs manual activation in AWS console)"
}

output "github_connection_status" {
  value       = module.cicd.github_connection_status
  description = "GitHub connection status (PENDING until activated in console)"
}

output "codepipeline_url" {
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${module.cicd.codepipeline_name}/view"
  description = "URL to view the CodePipeline in AWS Console"
}

output "ci_codebuild_project_name" {
  value       = module.cicd.ci_codebuild_project_name
  description = "Name of the CI CodeBuild project"
}

output "deploy_codebuild_project_name" {
  value       = module.cicd.deploy_codebuild_project_name
  description = "Name of the Deploy CodeBuild project"
}

output "artifacts_bucket_name" {
  value       = module.cicd.artifacts_bucket_name
  description = "Name of the S3 bucket for CodePipeline artifacts"
}
