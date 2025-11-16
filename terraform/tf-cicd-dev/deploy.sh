#!/bin/bash

# CI/CD Deployment Script for Module 3
# This script helps deploy the CI/CD infrastructure

set -e

echo "🚀 Starting CI/CD Infrastructure Deployment for Module 3"

# Check if we're in the correct directory
if [ ! -f "terraform.tfvars.example" ]; then
    echo "❌ Error: Please run this script from the terraform/tf-cicd-dev directory"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars not found. Please create it from the example:"
    echo "   cp terraform.tfvars.example terraform.tfvars"
    echo "   Edit terraform.tfvars and add your GitHub token"
    exit 1
fi

echo "✅ Checking prerequisites..."

# Check if GitHub token is set (not the placeholder)
if grep -q "your_github_personal_access_token_here" terraform.tfvars; then
    echo "❌ Error: Please replace the placeholder GitHub token in terraform.tfvars"
    echo "   Get your token from: https://github.com/settings/tokens"
    echo "   Required scopes: repo, admin:repo_hook"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "🤔 Do you want to apply these changes? (y/N): " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "🚀 Applying Terraform configuration..."
    terraform apply tfplan
    
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "📊 Pipeline Information:"
    terraform output
    
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Commit your code changes to trigger the pipeline"
    echo "2. Monitor the pipeline in AWS CodePipeline console"
    echo "3. Check CodeBuild logs for build progress"
    echo "4. Verify deployment in ECS console"
    
    echo ""
    echo "🔗 Useful Links:"
    echo "- CodePipeline: $(terraform output -raw codepipeline_url)"
    echo "- AWS Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines"
else
    echo "❌ Deployment cancelled"
fi

# Clean up plan file
rm -f tfplan

echo "🏁 Script completed!"