terraform {
  required_version = ">= 1.0"
  
  # Remote state backend (uncomment after creating backend with tf-backend/)
  # backend "s3" {
  #   bucket         = "setadvanced-terraform-state"
  #   key            = "environments/qa/terraform.tfstate"
  #   region         = "eu-north-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}