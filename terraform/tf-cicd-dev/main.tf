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
  name = "app-lb-dev"
}

# Get existing target group (blue)
data "aws_lb_target_group" "app_tg" {
  name = "app-tg-dev"
}

# Get existing listener
data "aws_lb_listener" "app_listener" {
  load_balancer_arn = data.aws_lb.app_lb.arn
  port              = 80
}

# CI/CD Module
module "cicd" {
  source = "../modules/tf-cicd"

  environment = "dev"
  
  # GitHub configuration
  github_owner  = "gula123"  # Replace with your GitHub username
  github_repo   = "setAdvancedApp"  # Replace with your repository name
  github_branch = "develop"  # Changed to develop branch
  github_token  = var.github_token  # Will be passed via variable

  # PR Validation
  enable_pr_validation = true  # Enable PR validation with Terraform checks

  # AWS resources
  region     = "eu-north-1"
  account_id = data.aws_caller_identity.current.account_id
  
  # ECR and ECS configuration
  ecr_repository_uri   = data.aws_ecr_repository.app_repo.repository_url
  ecs_cluster_name     = "app-cluster-dev"  # From your existing infrastructure
  ecs_service_name     = "app-service-dev"  # From your existing infrastructure
  lambda_function_name = "image-processing-lambda-dev"  # From your existing infrastructure
  s3_bucket_name       = "setadvanced-gula-dev"  # From your existing infrastructure
  
  # Project configuration
  project_name   = "setadvanced"
  container_name = "app-container"
  
  # Standard deployment configuration (no Blue-Green for DEV)
  target_group_name = data.aws_lb_target_group.app_tg.name
  target_group_arn  = data.aws_lb_target_group.app_tg.arn
  alb_dns_name      = data.aws_lb.app_lb.dns_name
}

# Outputs
output "codepipeline_name" {
  value       = module.cicd.codepipeline_name
  description = "Name of the CodePipeline"
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