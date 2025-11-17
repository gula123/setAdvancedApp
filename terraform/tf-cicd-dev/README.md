# CI/CD Pipeline - DEV Environment

This directory contains Terraform configuration for the DEV environment CI/CD pipeline using AWS CodePipeline, CodeBuild, and GitHub integration.

## Architecture Overview

The DEV CI/CD pipeline implements **standard ECS rolling updates** with automated deployment:

### Pipeline Stages

1. **Source**: GitHub repository (main branch)
2. **CI_Build**: Quality checks, linting, unit tests
3. **Deploy_Build**: Docker image build and push to ECR
4. **Deploy_ECS**: Direct deployment to ECS service

### Deployment Strategy

- **Type**: ECS Rolling Update
- **Zero Manual Steps**: Fully automated from commit to deployment
- **Fast Feedback**: Quick iterations for development
- **No Approval Gates**: Continuous deployment on successful build

## Components Created

### CodePipeline Stages:
1. **Source**: GitHub repository integration
2. **CI_Build**: Quality checks and tests
3. **Deploy_Build**: Build and package artifacts
4. **Deploy**: Deploy to ECS service

### CodeBuild Projects:
- **setadvanced-ci-dev**: Runs CI checks and tests
- **setadvanced-deploy-dev**: Builds and deploys application

### AWS Resources:
- S3 bucket for CodePipeline artifacts
- IAM roles and policies for CodeBuild and CodePipeline
- CloudWatch Event Rules for automation
- ECR integration for container images

## Prerequisites

1. **GitHub Repository**: Your code must be in a GitHub repository
2. **GitHub Personal Access Token**: Required for CodePipeline to access your repository
3. **Existing Infrastructure**: The application infrastructure from modules 1 & 2 must be deployed

## Setup Instructions

### 1. Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token"
3. Select the following scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Full control of repository hooks)
4. Copy the generated token

### 2. Configure Terraform Variables

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and add your GitHub token:
   ```hcl
   github_token = "your_github_personal_access_token_here"
   ```

### 3. Update GitHub Repository Information

Edit `main.tf` and update the GitHub configuration:
```hcl
module "cicd" {
  # ...
  github_owner  = "your-github-username"
  github_repo   = "your-repository-name"
  github_branch = "main"  # or your preferred branch
  # ...
}
```

### 4. Deploy CI/CD Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Buildspec Files

The pipeline uses two buildspec files in the root directory:

### `buildspec-ci.yml`
- Runs quality checks, linting, and tests
- Validates code quality and coverage
- Fails pipeline if quality gates are not met

### `buildspec-deploy.yml`
- Builds Spring Boot application
- Creates Docker image and pushes to ECR
- Packages Lambda function and deploys to AWS Lambda
- Generates ECS deployment manifest

## Pipeline Workflow

1. **Trigger**: Push to configured GitHub branch
2. **Source**: CodePipeline pulls latest code from GitHub
3. **CI Build**: 
   - Run linting and static analysis
   - Execute unit tests with coverage
   - Validate application configuration
4. **Deploy Build**:
   - Build Spring Boot JAR
   - Create and push Docker image
   - Package and deploy Lambda function
   - Generate ECS deployment manifest
5. **Deploy**: Update ECS service with new image

## Quality Gates

### CI Stage:
- Code linting (Checkstyle)
- Unit test coverage > 80%
- Static code analysis
- Compilation success

### Deployment Stage:
- Successful image build
- Lambda function deployment
- ECS health checks

## Monitoring and Troubleshooting

### View Pipeline Status:
```bash
# Get pipeline URL from Terraform output
terraform output codepipeline_url
```

### Monitor CodeBuild Logs:
- Go to AWS CodeBuild console
- Select the build project
- View build history and logs

### Common Issues:

1. **GitHub Token Issues**: Ensure token has correct permissions
2. **ECR Authentication**: CodeBuild role needs ECR access
3. **ECS Deployment**: Verify cluster and service names match existing infrastructure
4. **Lambda Deployment**: Ensure S3 bucket exists and Lambda function is deployed

## Security Considerations

- GitHub token is marked as sensitive in Terraform
- All IAM roles follow principle of least privilege
- S3 bucket has encryption and public access blocked
- ECR images are scanned for vulnerabilities

## Next Steps

After successful deployment:

1. Test the pipeline by making a commit to your configured branch
2. Monitor the pipeline execution in AWS CodePipeline console
3. Verify application deployment in ECS console
4. Check Lambda function updates in AWS Lambda console
5. Implement Blue-Green deployment strategy (Module 3 Task 2)

## Blue-Green Deployment (Task 2) ✅

This implementation includes **complete Blue-Green deployment automation** using AWS CodeDeploy:

### Features Implemented:
- **CodeDeploy Application**: Manages blue-green deployments
- **Deployment Groups**: Configures ECS service deployment strategy
- **Auto Rollback**: Automatically rolls back failed deployments
- **Health Checks**: Validates application health during deployment
- **Traffic Shifting**: Gradually shifts traffic from blue to green
- **Automatic Cleanup**: Terminates blue environment after successful deployment

### Blue-Green Workflow:
1. **Green Deployment**: CodeDeploy creates new ECS tasks (Green)
2. **Health Validation**: Performs health checks on Green environment
3. **Traffic Shift**: Gradually routes traffic from Blue to Green
4. **Monitoring**: Monitors application metrics and health
5. **Cleanup**: Automatically terminates Blue tasks if deployment succeeds
6. **Rollback**: Immediately routes traffic back to Blue if issues detected

### Configuration Files:
- **`taskdef.json`**: ECS task definition template for CodeDeploy
- **`appspec.yaml`**: CodeDeploy application specification
- **Blue-Green Terraform**: Complete infrastructure for automated deployments

This implementation fulfills **Task 2 requirements** and provides enterprise-grade CI/CD with zero-downtime deployments.