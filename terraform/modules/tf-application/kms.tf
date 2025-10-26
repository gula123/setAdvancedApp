# KMS key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs_key" {
  description             = "KMS key for CloudWatch Logs encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "cloudwatch-logs-key-${var.environment}"
    Environment = var.environment
    Purpose     = "CloudWatch Logs encryption"
  }
}

# KMS key alias for CloudWatch Logs
resource "aws_kms_alias" "cloudwatch_logs_key_alias" {
  name          = "alias/cloudwatch-logs-${var.environment}"
  target_key_id = aws_kms_key.cloudwatch_logs_key.key_id
}

# KMS key for Lambda environment variables encryption
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda environment variables encryption in ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda Service"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "lambda-key-${var.environment}"
    Environment = var.environment
    Purpose     = "Lambda encryption"
  }
}

# KMS key alias for Lambda
resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/lambda-${var.environment}"
  target_key_id = aws_kms_key.lambda_key.key_id
}