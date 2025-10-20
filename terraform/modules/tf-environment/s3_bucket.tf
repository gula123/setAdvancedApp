# S3 bucket for storing images
resource "aws_s3_bucket" "image_bucket" {
  bucket = "${var.bucket_name}-gula-${var.environment}"

  tags = {
    Name        = "${var.bucket_name}-gula-${var.environment}"
    Environment = var.environment
  }
}

# S3 bucket public access block configuration
resource "aws_s3_bucket_public_access_block" "image_bucket_pab" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "image_bucket_ownership" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket_public_access_block.image_bucket_pab]
}

# S3 bucket ACL for public read access
resource "aws_s3_bucket_acl" "image_bucket_acl" {
  bucket = aws_s3_bucket.image_bucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.image_bucket_ownership,
    aws_s3_bucket_public_access_block.image_bucket_pab
  ]
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.image_bucket_pab]
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "image_bucket_notification" {
  bucket = aws_s3_bucket.image_bucket.id

  topic {
    topic_arn = aws_sns_topic.image_notification.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.image_notification_policy]
}