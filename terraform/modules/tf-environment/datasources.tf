# Get current AWS region
data "aws_region" "current" {}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# IAM policy document for S3 bucket
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "AllowECSPutObjects"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      aws_s3_bucket.image_bucket.arn,
      "${aws_s3_bucket.image_bucket.arn}/*"
    ]
  }

  statement {
    sid = "AllowLambdaGetObjects"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.image_bucket.arn,
      "${aws_s3_bucket.image_bucket.arn}/*"
    ]
  }
}

# IAM policy document for SNS topic
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid = "AllowS3Publish"
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.image_notification.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.image_bucket.arn]
    }
  }
}

# IAM policy document for SQS queue
data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    sid = "AllowSNSSendMessages"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "SQS:SendMessage"
    ]
    resources = [
      aws_sqs_queue.image_processing_queue.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.image_notification.arn]
    }
  }
}