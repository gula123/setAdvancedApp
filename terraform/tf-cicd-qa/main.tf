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

# QA Environment CI/CD Pipeline
module "cicd_pipeline_qa" {
  source = "../modules/tf-cicd"

  # Environment Configuration
  environment = "qa"
  project_name = "setadvanced"

  # GitHub Configuration
  github_owner  = "gula123"
  github_repo   = "setAdvancedApp"
  github_branch = "release"  # QA pipeline triggered by release branch
  github_token  = var.github_token

  # AWS Configuration
  region     = "eu-north-1"
  account_id = var.account_id

  # ECR Repository
  ecr_repository_uri = var.ecr_repository_uri

  # ECS Configuration
  ecs_cluster_name = "app-cluster-qa"
  ecs_service_name = "app-service-qa"
  container_name   = "app-container-qa"

  # Lambda Configuration
  lambda_function_name = "image-processing-lambda-qa"

  # S3 Configuration
  s3_bucket_name = var.s3_bucket_name

  # ALB Target Group
  target_group_name = "app-tg-qa"

  # Blue-Green Deployment Hook
  blue_green_hook_lambda_name = "blue-green-hook-lambda-qa"
}