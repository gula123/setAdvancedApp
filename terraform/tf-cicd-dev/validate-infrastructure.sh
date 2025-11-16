#!/bin/bash

# Infrastructure Validation Script for CI/CD Pipeline
# Checks if all required resources exist before deploying CI/CD

echo "🔍 Validating existing infrastructure for CI/CD deployment..."

# Set AWS region
export AWS_DEFAULT_REGION=eu-north-1

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI not configured or no valid credentials"
    exit 1
fi

echo "✅ AWS CLI configured"

# Check ECR repository
echo "🔍 Checking ECR repository..."
if aws ecr describe-repositories --repository-names set/setadvancedrepository &> /dev/null; then
    echo "✅ ECR repository 'set/setadvancedrepository' exists"
else
    echo "❌ ECR repository 'set/setadvancedrepository' not found"
    echo "   Please create it or update the repository name in main.tf"
    exit 1
fi

# Check ECS cluster
echo "🔍 Checking ECS cluster..."
if aws ecs describe-clusters --clusters app-cluster-dev --query 'clusters[0].status' --output text | grep -q "ACTIVE"; then
    echo "✅ ECS cluster 'app-cluster-dev' is active"
else
    echo "❌ ECS cluster 'app-cluster-dev' not found or not active"
    echo "   Please deploy infrastructure from modules 1 & 2 first"
    exit 1
fi

# Check ECS service
echo "🔍 Checking ECS service..."
if aws ecs describe-services --cluster app-cluster-dev --services app-service-dev --query 'services[0].status' --output text | grep -q "ACTIVE"; then
    echo "✅ ECS service 'app-service-dev' is active"
else
    echo "❌ ECS service 'app-service-dev' not found or not active"
    echo "   Please deploy infrastructure from modules 1 & 2 first"
    exit 1
fi

# Check Lambda function
echo "🔍 Checking Lambda function..."
if aws lambda get-function --function-name image-processing-lambda-dev &> /dev/null; then
    echo "✅ Lambda function 'image-processing-lambda-dev' exists"
else
    echo "❌ Lambda function 'image-processing-lambda-dev' not found"
    echo "   Please deploy infrastructure from modules 1 & 2 first"
    exit 1
fi

# Check S3 bucket
echo "🔍 Checking S3 bucket..."
if aws s3 ls s3://setadvanced-gula-dev &> /dev/null; then
    echo "✅ S3 bucket 'setadvanced-gula-dev' exists"
else
    echo "❌ S3 bucket 'setadvanced-gula-dev' not found"
    echo "   Please deploy infrastructure from modules 1 & 2 first"
    exit 1
fi

# Check ALB Target Group
echo "🔍 Checking ALB Target Group..."
if aws elbv2 describe-target-groups --names app-tg-dev &> /dev/null; then
    echo "✅ Target Group 'app-tg-dev' exists"
else
    echo "❌ Target Group 'app-tg-dev' not found"
    echo "   Please deploy infrastructure from modules 1 & 2 first"
    exit 1
fi

echo ""
echo "🎉 All infrastructure validation checks passed!"
echo "✅ Ready to deploy CI/CD pipeline"
echo ""
echo "Next steps:"
echo "1. Create terraform.tfvars with your GitHub token"
echo "2. Run: terraform init && terraform plan && terraform apply"
echo "3. Commit code changes to trigger the pipeline"