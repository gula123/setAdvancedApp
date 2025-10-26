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

# Dead Letter Queue for Lambda function
resource "aws_sqs_queue" "lambda_dlq" {
  name                       = "lambda-dlq-${var.environment}"
  message_retention_seconds  = 1209600  # 14 days
  kms_master_key_id         = var.sqs_kms_key_arn != "" ? var.sqs_kms_key_arn : null

  tags = {
    Name        = "lambda-dlq-${var.environment}"
    Environment = var.environment
  }
}

# Lambda code signing configuration (optional for enhanced security)
# Commented out as it requires signing profile ARNs which are not needed for demo
# resource "aws_lambda_code_signing_config" "code_signing_config" {
#   allowed_publishers {
#     signing_profile_version_arns = [
#       # This would be your signing profile ARN in production
#       # For demo purposes, we'll allow unsigned code
#     ]
#   }
#
#   policies {
#     untrusted_artifact_on_deployment = "Warn"  # Allow deployment but warn
#   }
#
#   description = "Code signing configuration for ${var.environment}"
#
#   tags = {
#     Name        = "lambda-code-signing-${var.environment}"
#     Environment = var.environment
#   }
# }

# Lambda function
resource "aws_lambda_function" "image_processing_lambda" {
  function_name    = "image-processing-lambda-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  filename        = data.archive_file.lambda_zip.output_path
  runtime         = "python3.10"
  handler         = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout         = 30
  
  # Set concurrent execution limit
  reserved_concurrent_executions = 10
  
  # Code signing configuration (commented out for demo)
  # code_signing_config_arn = aws_lambda_code_signing_config.code_signing_config.arn
  
  # Configure Dead Letter Queue
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
  
  # Encrypt environment variables
  kms_key_arn = aws_kms_key.lambda_key.arn
  
  # Enable X-Ray tracing for monitoring
  tracing_config {
    mode = "Active"
  }
  
  # Configure VPC (will add subnet IDs and security group)
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME     = var.s3_bucket_name
      SQS_QUEUE_URL      = var.sqs_queue_url
      # AWS region is automatically detected by boto3 in Lambda environment
    }
  }

  tags = {
    Name        = "image-processing-lambda-${var.environment}"
    Environment = var.environment
  }
}

# Security group for Lambda function
resource "aws_security_group" "lambda_sg" {
  name_prefix = "lambda-sg-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Security group for Lambda function"

  # Allow HTTPS outbound for AWS API calls
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "HTTPS to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP outbound for VPC endpoints
  egress {
    description = "HTTP to VPC endpoints"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "lambda-sg-${var.environment}"
    Environment = var.environment
  }
}

# Lambda event source mapping for SQS
resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.image_processing_lambda.arn
  batch_size       = 1
}