output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket for Terraform state"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket for Terraform state"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_state_lock.name
  description = "Name of the DynamoDB table for state locking"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.terraform_state_lock.arn
  description = "ARN of the DynamoDB table for state locking"
}

output "backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
  }
  description = "Backend configuration values for other Terraform configurations"
}

# Print instructions for using the backend
output "usage_instructions" {
  value = <<-EOT
    
    Backend created successfully! 
    
    To use this backend in your other Terraform configurations, add this to your terraform block:
    
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.bucket}"
        key            = "environments/<env-name>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
        encrypt        = true
      }
    }
    
    Replace <env-name> with: dev, qa, or prod
    
  EOT
  description = "Instructions for using the created backend"
}