@echo off
setlocal enabledelayedexpansion

echo 🔍 Validating existing infrastructure for CI/CD deployment...

REM Set AWS region
set AWS_DEFAULT_REGION=eu-north-1

REM Check if AWS CLI is configured
aws sts get-caller-identity >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ AWS CLI not configured or no valid credentials
    exit /b 1
)

echo ✅ AWS CLI configured

REM Check ECR repository
echo 🔍 Checking ECR repository...
aws ecr describe-repositories --repository-names set/setadvancedrepository >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ ECR repository 'set/setadvancedrepository' exists
) else (
    echo ❌ ECR repository 'set/setadvancedrepository' not found
    echo    Please create it or update the repository name in main.tf
    exit /b 1
)

REM Check ECS cluster
echo 🔍 Checking ECS cluster...
for /f "delims=" %%i in ('aws ecs describe-clusters --clusters app-cluster-dev --query "clusters[0].status" --output text 2^>nul') do set cluster_status=%%i
if "!cluster_status!" == "ACTIVE" (
    echo ✅ ECS cluster 'app-cluster-dev' is active
) else (
    echo ❌ ECS cluster 'app-cluster-dev' not found or not active
    echo    Please deploy infrastructure from modules 1 ^& 2 first
    exit /b 1
)

REM Check ECS service
echo 🔍 Checking ECS service...
for /f "delims=" %%i in ('aws ecs describe-services --cluster app-cluster-dev --services app-service-dev --query "services[0].status" --output text 2^>nul') do set service_status=%%i
if "!service_status!" == "ACTIVE" (
    echo ✅ ECS service 'app-service-dev' is active
) else (
    echo ❌ ECS service 'app-service-dev' not found or not active
    echo    Please deploy infrastructure from modules 1 ^& 2 first
    exit /b 1
)

REM Check Lambda function
echo 🔍 Checking Lambda function...
aws lambda get-function --function-name image-processing-lambda-dev >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Lambda function 'image-processing-lambda-dev' exists
) else (
    echo ❌ Lambda function 'image-processing-lambda-dev' not found
    echo    Please deploy infrastructure from modules 1 ^& 2 first
    exit /b 1
)

REM Check S3 bucket
echo 🔍 Checking S3 bucket...
aws s3 ls s3://setadvanced-gula-dev >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ S3 bucket 'setadvanced-gula-dev' exists
) else (
    echo ❌ S3 bucket 'setadvanced-gula-dev' not found
    echo    Please deploy infrastructure from modules 1 ^& 2 first
    exit /b 1
)

REM Check ALB Target Group
echo 🔍 Checking ALB Target Group...
aws elbv2 describe-target-groups --names app-tg-dev >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Target Group 'app-tg-dev' exists
) else (
    echo ❌ Target Group 'app-tg-dev' not found
    echo    Please deploy infrastructure from modules 1 ^& 2 first
    exit /b 1
)

echo.
echo 🎉 All infrastructure validation checks passed!
echo ✅ Ready to deploy CI/CD pipeline
echo.
echo Next steps:
echo 1. Create terraform.tfvars with your GitHub token
echo 2. Run: terraform init ^&^& terraform plan ^&^& terraform apply
echo 3. Commit code changes to trigger the pipeline