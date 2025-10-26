# Central audit logging bucket for environment S3 access logs
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "environment_audit_logs" {
  bucket        = "env-audit-logs-${var.environment}-${random_string.audit_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "env-audit-logs-${var.environment}"
    Environment = var.environment
    Purpose     = "environment-audit-logging"
  }
}

resource "random_string" "audit_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Enable versioning for environment audit logs bucket
resource "aws_s3_bucket_versioning" "environment_audit_logs_versioning" {
  bucket = aws_s3_bucket.environment_audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for environment audit logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "environment_audit_logs_encryption" {
  bucket = aws_s3_bucket.environment_audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Enable versioning for environment audit logs bucket
resource "aws_s3_bucket_versioning" "environment_audit_logs_versioning" {
  bucket = aws_s3_bucket.environment_audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration for environment audit logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "environment_audit_logs_lifecycle" {
  bucket = aws_s3_bucket.environment_audit_logs.id

  rule {
    id     = "environment_audit_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Block public access for environment audit logs bucket
resource "aws_s3_bucket_public_access_block" "environment_audit_logs_pab" {
  bucket = aws_s3_bucket.environment_audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}