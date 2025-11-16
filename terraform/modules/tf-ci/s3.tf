# S3 Bucket for CI artifacts storage
resource "random_string" "ci_bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "ci_artifacts" {
  bucket = "${var.project_name}-ci-artifacts-${random_string.ci_bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-ci-artifacts-${var.environment}"
    Environment = var.environment
    Purpose     = "CI Pipeline Artifacts"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ci_artifacts_encryption" {
  bucket = aws_s3_bucket.ci_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ci_artifacts_pab" {
  bucket = aws_s3_bucket.ci_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ci_artifacts_versioning" {
  bucket = aws_s3_bucket.ci_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ci_artifacts_lifecycle" {
  bucket = aws_s3_bucket.ci_artifacts.id

  rule {
    id     = "ci_artifacts_cleanup"
    status = "Enabled"

    expiration {
      days = 7  # Keep CI artifacts for only 7 days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}