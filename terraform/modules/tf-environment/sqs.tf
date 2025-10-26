# SQS queue for processing image notifications
resource "aws_sqs_queue" "image_processing_queue" {
  name                    = var.sqs_name
  fifo_queue             = false
  kms_master_key_id      = aws_kms_key.sqs_key.arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name        = var.sqs_name
    Environment = var.environment
  }
}

# SQS queue policy
resource "aws_sqs_queue_policy" "image_processing_queue_policy" {
  queue_url = aws_sqs_queue.image_processing_queue.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}