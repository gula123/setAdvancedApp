# Lambda IAM Role
resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name        = "lambda-execution-role-${var.environment}"
    Environment = var.environment
  }
}

# Lambda IAM Policy
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy-${var.environment}"
  description = "IAM policy for Lambda function"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function
resource "aws_lambda_function" "image_processing_lambda" {
  function_name    = "image-processing-lambda-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  filename        = data.archive_file.lambda_zip.output_path
  runtime         = "python3.10"
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME     = var.s3_bucket_name
      # AWS region is automatically detected by boto3 in Lambda environment
    }
  }

  tags = {
    Name        = "image-processing-lambda-${var.environment}"
    Environment = var.environment
  }
}

# Lambda event source mapping for SQS
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.image_processing_lambda.arn
  batch_size       = 1
}