# SNS topic for ALB S3 event notifications
resource "aws_sns_topic" "alb_s3_events" {
  name              = "alb-s3-events-${var.environment}"
  kms_master_key_id = aws_kms_key.cloudwatch_logs_key.id

  tags = {
    Name        = "alb-s3-events-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_sns_topic_policy" "alb_s3_events_policy" {
  arn = aws_sns_topic.alb_s3_events.arn

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
        Resource = aws_sns_topic.alb_s3_events.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# S3 event notification for ALB logs bucket
resource "aws_s3_bucket_notification" "alb_logs_notification" {
  bucket = aws_s3_bucket.alb_logs.id

  topic {
    topic_arn = aws_sns_topic.alb_s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "alb-logs/"
  }

  depends_on = [aws_sns_topic_policy.alb_s3_events_policy]
}

# S3 event notification for ALB logs access logs bucket
resource "aws_s3_bucket_notification" "alb_logs_access_logs_notification" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  topic {
    topic_arn = aws_sns_topic.alb_s3_events.arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "alb-access-logs/"
  }

  depends_on = [aws_sns_topic_policy.alb_s3_events_policy]
}