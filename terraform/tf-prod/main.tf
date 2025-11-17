# Configure AWS Provider
provider "aws" {
  region = "eu-north-1"  # Change this to your preferred region
}

module "environment" {
  source = "../modules/tf-environment"

  bucket_name          = "setadvanced-gula-prod"
  sns_name            = "image-notification-topic-prod"
  sqs_name            = "image-processing-queue-prod"
  dynamodb_table_name = "image-recognition-results-prod"
  environment         = "prod"
  vpc_cidr_third_octet = 3
}

module "application" {
  source = "../modules/tf-application"
  
  s3_bucket_name      = module.environment.s3_bucket_name
  dynamodb_table_name = module.environment.dynamodb_table_name
  subnet_ids          = module.environment.default_subnet_ids
  private_subnet_ids  = module.environment.private_subnet_ids
  vpc_id              = module.environment.default_vpc_id
  vpc_cidr            = module.environment.vpc_cidr
  region_name         = module.environment.default_region_name
  sqs_queue_arn       = module.environment.sqs_queue_arn
  sqs_queue_url       = module.environment.sqs_queue_url
  sqs_kms_key_arn     = module.environment.sqs_kms_key_arn
  dynamodb_kms_key_arn = module.environment.dynamodb_kms_key_arn
  s3_kms_key_arn      = module.environment.s3_kms_key_arn
  image_uri           = "236292171120.dkr.ecr.eu-north-1.amazonaws.com/set/setadvancedrepository:latest"
  environment         = "prod"
  application_port    = 8080
  enable_https        = false
  enable_blue_green_deployment = true  # Blue-Green deployment for PROD only
}

# Outputs
output "load_balancer_url" {
  value       = "http://${module.application.load_balancer_dns_name}"
  description = "URL of the application load balancer"
}

output "s3_bucket_name" {
  value       = module.environment.s3_bucket_name
  description = "Name of the S3 bucket for image uploads"
}

output "dynamodb_table_name" {
  value       = module.environment.dynamodb_table_name
  description = "Name of the DynamoDB table for recognition results"
}