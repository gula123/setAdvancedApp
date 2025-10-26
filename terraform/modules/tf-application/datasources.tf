# Archive lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Get AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# IAM policy for Lambda execution role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM policy for Lambda function permissions
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [var.sqs_queue_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = ["arn:aws:dynamodb:${var.region_name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "rekognition:DetectLabels"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region_name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
      "arn:aws:logs:${var.region_name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"
    ]
  }

  # DLQ permissions
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs:${var.region_name}:${data.aws_caller_identity.current.account_id}:lambda-dlq-${var.environment}"]
  }

  # VPC and ENI permissions for Lambda in VPC
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface"
    ]
    resources = [
      "arn:aws:ec2:${var.region_name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  # X-Ray tracing permissions
  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = [
      "arn:aws:xray:${var.region_name}:${data.aws_caller_identity.current.account_id}:trace/*"
    ]
  }
}

# IAM policy for ECS task execution role
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Predefined AWS policies
data "aws_iam_policy" "ecs_execution_role_policy" {
  name = "AWSAppRunnerServicePolicyForECRAccess"
}

data "aws_iam_policy" "cloudwatch_logs_full_access" {
  name = "CloudWatchLogsFullAccess"
}

data "aws_iam_policy" "s3_full_access" {
  name = "AmazonS3FullAccess"
}

data "aws_iam_policy" "dynamodb_full_access" {
  name = "AmazonDynamoDBFullAccess"
}