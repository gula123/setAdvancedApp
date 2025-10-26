# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

# S3 bucket for Terraform state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Purpose     = "terraform-backend"
    Environment = "shared"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# KMS key for S3 encryption
resource "aws_kms_key" "s3_backend_key" {
  description             = "KMS key for Terraform backend S3 bucket encryption"
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
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
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
    Name        = "terraform-backend-s3-key"
    Purpose     = "terraform-backend"
    Environment = "shared"
  }
}

resource "aws_kms_alias" "s3_backend_key_alias" {
  name          = "alias/terraform-backend-s3"
  target_key_id = aws_kms_key.s3_backend_key.key_id
}

# Access logs bucket for the main state bucket
resource "aws_s3_bucket" "terraform_state_access_logs" {
  bucket        = "${var.state_bucket_name}-access-logs"
  force_destroy = true

  tags = {
    Name        = "Terraform State Access Logs"
    Purpose     = "terraform-backend-logging"
    Environment = "shared"
  }
}

# SNS topic for S3 event notifications
resource "aws_sns_topic" "terraform_backend_s3_events" {
  name              = "terraform-backend-s3-events"
  kms_master_key_id = aws_kms_key.s3_backend_key.id

  tags = {
    Name        = "terraform-backend-s3-events"
    Purpose     = "terraform-backend"
    Environment = "shared"
  }
}

resource "aws_sns_topic_policy" "terraform_backend_s3_events_policy" {
  arn = aws_sns_topic.terraform_backend_s3_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Publish"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.terraform_backend_s3_events.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 event notification for terraform state bucket
resource "aws_s3_bucket_notification" "terraform_state_notification" {
  bucket = aws_s3_bucket.terraform_state.id

  topic {
    topic_arn = aws_sns_topic.terraform_backend_s3_events.arn
    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*"
    ]
  }

  depends_on = [aws_sns_topic_policy.terraform_backend_s3_events_policy]
}

# S3 event notification for terraform state access logs bucket
resource "aws_s3_bucket_notification" "terraform_state_access_logs_notification" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id

  topic {
    topic_arn = aws_sns_topic.terraform_backend_s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "access-logs/"
  }

  depends_on = [aws_sns_topic_policy.terraform_backend_s3_events_policy]
}

resource "aws_s3_bucket_public_access_block" "terraform_state_access_logs_pab" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for terraform state access logs bucket
resource "aws_s3_bucket_versioning" "terraform_state_access_logs_versioning" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for terraform state access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_access_logs_encryption" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_backend_key.arn
    }
    bucket_key_enabled = true
  }
}

# Central audit logging bucket for terraform backend
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "backend_audit_logs" {
  bucket        = "${var.state_bucket_name}-backend-audit"
  force_destroy = true

  tags = {
    Name        = "Backend Audit Logs"
    Purpose     = "terraform-backend-audit-logging"
    Environment = "shared"
  }
}

resource "aws_s3_bucket_public_access_block" "backend_audit_logs_pab" {
  bucket = aws_s3_bucket.backend_audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backend_audit_logs_versioning" {
  bucket = aws_s3_bucket.backend_audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backend_audit_logs_lifecycle" {
  bucket = aws_s3_bucket.backend_audit_logs.id

  rule {
    id     = "backend_audit_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_audit_logs_encryption" {
  bucket = aws_s3_bucket.backend_audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_backend_key.arn
    }
    bucket_key_enabled = true
  }
}

# Enable logging for terraform state access logs bucket
resource "aws_s3_bucket_logging" "terraform_state_access_logs_logging" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id

  target_bucket = aws_s3_bucket.backend_audit_logs.id
  target_prefix = "terraform-access-logs/"
}

# Lifecycle configuration for terraform state access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_access_logs_lifecycle" {
  bucket = aws_s3_bucket.terraform_state_access_logs.id

  rule {
    id     = "delete_old_access_logs"
    status = "Enabled"

    expiration {
      days = 365  # Keep access logs for 1 year
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Enable server-side encryption for the S3 bucket with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_backend_key.arn
    }
    bucket_key_enabled = true
  }
}

# Enable access logging
resource "aws_s3_bucket_logging" "terraform_state_logging" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_access_logs.id
  target_prefix = "access-logs/"
}

# Add lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Transition old versions to cheaper storage classes
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    # Delete very old versions
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_pab" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for DynamoDB encryption
resource "aws_kms_key" "dynamodb_backend_key" {
  description             = "KMS key for Terraform backend DynamoDB table encryption"
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
        Sid    = "Allow DynamoDB Service"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
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
    Name        = "terraform-backend-dynamodb-key"
    Purpose     = "terraform-backend"
    Environment = "shared"
  }
}

resource "aws_kms_alias" "dynamodb_backend_key_alias" {
  name          = "alias/terraform-backend-dynamodb"
  target_key_id = aws_kms_key.dynamodb_backend_key.key_id
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Enable server-side encryption with customer-managed KMS key
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_backend_key.arn
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Prevent accidental deletion of this table
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Purpose     = "terraform-backend"
    Environment = "shared"
  }
}