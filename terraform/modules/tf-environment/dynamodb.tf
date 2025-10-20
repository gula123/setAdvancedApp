# DynamoDB table for storing recognition results
resource "aws_dynamodb_table" "image_recognition_results" {
  name           = "${var.dynamodb_table_name}-${var.environment}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"
  range_key      = "objectPath"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "objectPath"
    type = "S"
  }

  tags = {
    Name        = "${var.dynamodb_table_name}-${var.environment}"
    Environment = var.environment
  }
}