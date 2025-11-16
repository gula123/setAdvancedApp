# PROD Environment CI/CD Pipeline
module "cicd_pipeline_prod" {
  source = "../modules/tf-cicd"

  # Environment Configuration
  environment = "prod"
  project_name = "setadvanced"

  # GitHub Configuration
  github_owner  = "gula123"
  github_repo   = "setAdvancedApp"
  github_branch = "main"  # PROD pipeline triggered by main branch
  github_token  = var.github_token

  # AWS Configuration
  region     = "eu-north-1"
  account_id = var.account_id

  # ECR Repository
  ecr_repository_uri = var.ecr_repository_uri

  # ECS Configuration
  ecs_cluster_name = "app-cluster-prod"
  ecs_service_name = "app-service-prod"
  container_name   = "app-container-prod"

  # Lambda Configuration
  lambda_function_name = "image-processing-lambda-prod"

  # S3 Configuration
  s3_bucket_name = var.s3_bucket_name

  # ALB Target Group
  target_group_name = "app-tg-prod"

  # Blue-Green Deployment Hook
  blue_green_hook_lambda_name = "blue-green-hook-lambda-prod"
}