# SQS queue for processing image notifications
resource "aws_sqs_queue" "image_processing_queue" {
  name       = "${var.sqs_name}-${var.environment}"
  fifo_queue = false

  tags = {
    Name        = "${var.sqs_name}-${var.environment}"
    Environment = var.environment
  }
}

# SQS queue policy
resource "aws_sqs_queue_policy" "image_processing_queue_policy" {
  queue_url = aws_sqs_queue.image_processing_queue.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}