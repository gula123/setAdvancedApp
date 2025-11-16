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

# CI/CD Module
module "cicd" {
  source = "../modules/tf-cicd"

  environment = "dev"
  
  # GitHub configuration
  github_owner  = "gula123"  # Replace with your GitHub username
  github_repo   = "setAdvancedApp"  # Replace with your repository name
  github_branch = "main"  # or "module3" if you want to use that branch
  github_token  = var.github_token  # Will be passed via variable

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
  container_name = "app"
  
  # Blue-Green deployment configuration
  target_group_name = "app-tg-dev"  # Matches your existing ALB target group
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