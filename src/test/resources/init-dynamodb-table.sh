#!/bin/bash
user_table_name="users"
partition_key="id"
image_table_name="image"

echo "Starting table creation in LocalStack..."

awslocal dynamodb create-table \
  --table-name "$user_table_name" \
  --key-schema AttributeName="$partition_key",KeyType=HASH \
  --attribute-definitions AttributeName="$partition_key",AttributeType=S \
  --billing-mode PAY_PER_REQUEST

awslocal dynamodb create-table \
--table-name "$image_table_name" \
--key-schema AttributeName="$partition_key",KeyType=HASH \
--attribute-definitions AttributeName="$partition_key",AttributeType=S \
--billing-mode PAY_PER_REQUEST

echo "DynamoDB tables '$table_name' created successfully with partition key '$partition_key'"
echo "Executed init-dynamodb-table.sh"