# CI/CD Pipeline - QA Environment

This directory contains Terraform configuration for the QA environment CI/CD pipeline using AWS CodePipeline, CodeBuild, and GitHub integration.

## Architecture Overview

The QA CI/CD pipeline implements **standard ECS rolling updates** with manual approval gates and integration testing.

### Pipeline Stages

1. **Source**: GitHub repository (release branch)
2. **CI_Build**: Quality checks, linting, unit tests
3. **Deploy_Build**: Docker image build and push to ECR
4. **Deploy_ECS**: Direct deployment to ECS service
5. **Manual_Approval**: Human review before promoting to testing
6. **Integration_Tests**: Automated end-to-end testing

### Deployment Strategy

- **Type**: ECS Rolling Update
- **Manual Approval**: Required before deployment
- **Integration Testing**: Automated validation after deployment
- **Release Branch**: Triggered by commits to `release` branch
- **Quality Gates**: Ensures stability before production

## Components Created

### CodePipeline
- **Name**: `setadvanced-pipeline-qa`
- **Trigger**: GitHub webhook on push to release branch
- **Stages**: 6 stages including approval and testing

### CodeBuild Projects
- **setadvanced-ci-qa**: CI checks and unit tests
- **setadvanced-deploy-qa**: Build and deploy application
- **setadvanced-integration-tests-qa**: End-to-end testing

### AWS Resources
- S3 bucket for CodePipeline artifacts
- IAM roles and policies for CodeBuild and CodePipeline
- CloudWatch Event Rules for automation
- Manual approval action in pipeline

## Prerequisites

1. **GitHub Repository**: Code in GitHub at `gula123/setAdvancedApp`
2. **GitHub Personal Access Token**: Required for CodePipeline
3. **QA Infrastructure**: Application infrastructure deployed in QA
4. **Release Branch**: `release` branch in GitHub

## Setup Instructions

### 1. Create GitHub Token Variable

```bash
# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
github_token = "YOUR_GITHUB_PERSONAL_ACCESS_TOKEN"
EOF
```

### 2. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify Pipeline

```bash
# Check pipeline status
aws codepipeline get-pipeline-state \
  --name setadvanced-pipeline-qa \
  --region eu-north-1

# View pipeline in console
# https://console.aws.amazon.com/codesuite/codepipeline/pipelines/setadvanced-pipeline-qa/view
```

## Pipeline Workflow

```
┌─────────────┐
│   GitHub    │ Push to release branch
│  (release)  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  CI Build   │ Linting, tests, validation
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Deploy Build │ Build Docker image, push to ECR
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Deploy ECS  │ Rolling update to ECS service
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Manual    │ 👤 Approve deployment
│  Approval   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Integration  │ Automated E2E tests
│   Tests     │
└─────────────┘
```

## Configuration

### GitHub Settings
- **Owner**: `gula123`
- **Repository**: `setAdvancedApp`
- **Branch**: `release`

### AWS Settings
- **Region**: `eu-north-1`
- **ECS Cluster**: `app-cluster-qa`
- **ECS Service**: `app-service-qa`
- **ECR Repository**: `set/setadvancedrepository`

## Outputs

After successful deployment, you'll see:

```hcl
codepipeline_name = "setadvanced-pipeline-qa"
codepipeline_url = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/setadvanced-pipeline-qa/view"
ci_codebuild_project_name = "setadvanced-ci-qa"
deploy_codebuild_project_name = "setadvanced-deploy-qa"
artifacts_bucket_name = "setadvanced-codepipeline-artifacts-qa-XXXXXXXX"
```

## Manual Approval Process

When the pipeline reaches the Manual Approval stage:

1. Navigate to the CodePipeline console
2. Review the deployment details
3. Click "Review" on the approval action
4. Add comments if needed
5. Click "Approve" or "Reject"

## Monitoring

### View Pipeline Executions
```bash
aws codepipeline list-pipeline-executions \
  --pipeline-name setadvanced-pipeline-qa \
  --region eu-north-1
```

### View Build Logs
```bash
# CI Build logs
aws logs tail /aws/codebuild/setadvanced-ci-qa --follow

# Deploy Build logs
aws logs tail /aws/codebuild/setadvanced-deploy-qa --follow

# Integration Test logs
aws logs tail /aws/codebuild/setadvanced-integration-tests-qa --follow
```

## Troubleshooting

### Pipeline Not Triggering
- Verify GitHub webhook is configured
- Check GitHub token permissions
- Review CloudWatch Event Rules

### Build Failures
- Check CodeBuild logs in CloudWatch
- Verify buildspec files exist in repository
- Ensure IAM roles have required permissions

### Deployment Failures
- Check ECS service events
- Verify task definition is valid
- Review security group and network configuration

## Cost Optimization

- **CodeBuild**: Pay per build minute
- **CodePipeline**: $1/month per active pipeline
- **S3 Artifacts**: Lifecycle policy deletes old artifacts after 30 days
- **CloudWatch Logs**: Logs retained as configured

## Security Features

- ✅ GitHub token stored as sensitive variable
- ✅ IAM roles with least-privilege permissions
- ✅ Encrypted S3 bucket for artifacts
- ✅ No secrets in buildspec files
- ✅ Manual approval before testing

## Next Steps

After QA approval:
1. Merge to `main` branch for PROD deployment
2. PROD uses Blue-Green deployment for zero downtime
3. Monitor application in QA environment
4. Review integration test results
