# SNS topic for S3 event notifications
resource "aws_sns_topic" "s3_events" {
  name              = "s3-events-${var.environment}"
  kms_master_key_id = aws_kms_key.sns_key.id

  tags = {
    Name        = "s3-events-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_sns_topic_policy" "s3_events_policy" {
  arn = aws_sns_topic.s3_events.arn

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
        Resource = aws_sns_topic.s3_events.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 event notification for access logs bucket
resource "aws_s3_bucket_notification" "access_logs_notification" {
  bucket = aws_s3_bucket.access_logs.id

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "access-logs/"
  }

  depends_on = [aws_sns_topic_policy.s3_events_policy]
}