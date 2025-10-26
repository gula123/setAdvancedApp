# SNS topic for image notifications
resource "aws_sns_topic" "image_notification" {
  name              = var.sns_name
  kms_master_key_id = aws_kms_key.sns_key.arn

  tags = {
    Name        = var.sns_name
    Environment = var.environment
  }
}

# SNS topic policy
resource "aws_sns_topic_policy" "image_notification_policy" {
  arn    = aws_sns_topic.image_notification.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# SNS topic subscription to SQS
resource "aws_sns_topic_subscription" "image_notification_subscription" {
  topic_arn = aws_sns_topic.image_notification.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.image_processing_queue.arn
}