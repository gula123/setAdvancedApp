terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# CodeStar Connection for GitHub
resource "aws_codestarconnections_connection" "github" {
  name          = "setadvanced-github-connection"
  provider_type = "GitHub"
}

# IAM policy for CodeConnections
resource "aws_iam_policy" "codeconnections" {
  name        = "CodeConnectionsPolicy"
  description = "Policy for CodeStar Connections"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:*",
          "codeconnections:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to your IAM user
resource "aws_iam_user_policy_attachment" "codeconnections_attach" {
  user       = "setAdvancedApp-local"
  policy_arn = aws_iam_policy.codeconnections.arn
}

output "connection_arn" {
  value       = aws_codestarconnections_connection.github.arn
  description = "GitHub connection ARN - use this in your pipelines"
}

output "connection_status" {
  value       = aws_codestarconnections_connection.github.connection_status
  description = "Connection status - will be PENDING until you complete setup in console"
}

output "setup_instructions" {
  value = <<-EOT
    Connection created! To activate:
    1. Go to: https://eu-north-1.console.aws.amazon.com/codesuite/settings/connections
    2. Find connection: ${aws_codestarconnections_connection.github.name}
    3. Click "Update pending connection"
    4. Click "Install a new app" or select existing GitHub App
    5. Authorize AWS Connector for GitHub
    6. Connection will become AVAILABLE
  EOT
  description = "Instructions to activate the connection"
}
