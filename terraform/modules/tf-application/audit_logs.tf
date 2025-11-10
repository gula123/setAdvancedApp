# Central audit logging bucket for S3 access logs
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "audit_logs" {
  bucket        = "audit-logs-${var.environment}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "audit-logs-${var.environment}"
    Environment = var.environment
    Purpose     = "central-audit-logging"
  }
}

# Enable versioning for audit logs bucket
resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for audit logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudwatch_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block public access for audit logs bucket
resource "aws_s3_bucket_public_access_block" "audit_logs_pab" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration for audit logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_lifecycle" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "audit_logs_lifecycle"
    status = "Enabled"

    filter {}

    expiration {
      days = 365  # Keep audit logs for 1 year
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}