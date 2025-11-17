@echo off
setlocal enabledelayedexpansion

echo 🚀 Starting CI/CD Infrastructure Deployment for Module 3

REM Check if we're in the correct directory
if not exist "terraform.tfvars.example" (
    echo ❌ Error: Please run this script from the terraform/tf-cicd-dev directory
    exit /b 1
)

REM Check if terraform.tfvars exists
if not exist "terraform.tfvars" (
    echo ⚠️  terraform.tfvars not found. Please create it from the example:
    echo    copy terraform.tfvars.example terraform.tfvars
    echo    Edit terraform.tfvars and add your GitHub token
    exit /b 1
)

echo ✅ Checking prerequisites...

REM Check if GitHub token is set (not the placeholder)
findstr "your_github_personal_access_token_here" terraform.tfvars >nul
if !errorlevel! == 0 (
    echo ❌ Error: Please replace the placeholder GitHub token in terraform.tfvars
    echo    Get your token from: https://github.com/settings/tokens
    echo    Required scopes: repo, admin:repo_hook
    exit /b 1
)

echo ✅ Prerequisites check passed

REM Initialize Terraform
echo 🔧 Initializing Terraform...
terraform init
if !errorlevel! neq 0 (
    echo ❌ Terraform init failed
    exit /b 1
)

REM Validate configuration
echo 🔍 Validating Terraform configuration...
terraform validate
if !errorlevel! neq 0 (
    echo ❌ Terraform validation failed
    exit /b 1
)

REM Plan deployment
echo 📋 Planning deployment...
terraform plan -out=tfplan
if !errorlevel! neq 0 (
    echo ❌ Terraform plan failed
    exit /b 1
)

REM Ask for confirmation
set /p confirm="🤔 Do you want to apply these changes? (y/N): "
if /i "!confirm!" == "y" (
    echo 🚀 Applying Terraform configuration...
    terraform apply tfplan
    if !errorlevel! neq 0 (
        echo ❌ Terraform apply failed
        exit /b 1
    )
    
    echo ✅ Deployment completed successfully!
    echo.
    echo 📊 Pipeline Information:
    terraform output
    
    echo.
    echo 🎯 Next Steps:
    echo 1. Commit your code changes to trigger the pipeline
    echo 2. Monitor the pipeline in AWS CodePipeline console
    echo 3. Check CodeBuild logs for build progress
    echo 4. Verify deployment in ECS console
    
    echo.
    echo 🔗 Useful Links:
    for /f "delims=" %%i in ('terraform output -raw codepipeline_url') do set pipeline_url=%%i
    echo - CodePipeline: !pipeline_url!
    echo - AWS Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines
) else (
    echo ❌ Deployment cancelled
)

REM Clean up plan file
if exist tfplan del tfplan

echo 🏁 Script completed!