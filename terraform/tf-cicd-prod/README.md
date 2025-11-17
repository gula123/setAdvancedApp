# CI/CD Pipeline - PROD Environment (Blue-Green Deployment)

This directory contains Terraform configuration for the PROD environment CI/CD pipeline using AWS CodePipeline, CodeBuild, and **CodeDeploy with Blue-Green deployment strategy**.

## Architecture Overview

The PROD CI/CD pipeline implements **Blue-Green deployment** for zero-downtime releases with automatic rollback capabilities.

### Pipeline Stages

1. **Source**: GitHub repository (main branch)
2. **CI_Build**: Quality checks, linting, unit tests
3. **Deploy_Build**: Docker image build, push to ECR, generate appspec
4. **Deploy_BlueGreen**: CodeDeploy orchestrates Blue-Green deployment

### Blue-Green Deployment Strategy

- **Type**: AWS CodeDeploy ECS Blue-Green
- **Target Groups**: Two ALB target groups (blue and green)
- **Traffic Shifting**: AllAtOnce (instant cutover)
- **Automatic Rollback**: On deployment failure
- **Zero Downtime**: Seamless traffic routing
- **Termination**: Old tasks terminated after 5 minutes

## Components Created

### CodePipeline
- **Name**: `setadvanced-pipeline-prod`
- **Trigger**: GitHub webhook on push to main branch
- **Stages**: 4 stages with Blue-Green deployment

### CodeBuild Projects
- **setadvanced-ci-prod**: CI checks and unit tests
- **setadvanced-deploy-prod**: Build image and generate deployment artifacts

### CodeDeploy
- **Application**: `setadvanced-app-prod`
- **Deployment Group**: `setadvanced-deployment-group-prod`
- **Compute Platform**: ECS
- **Deployment Config**: `setadvanced-ECSBlueGreen-prod` (AllAtOnce)

### Target Groups
- **Blue**: `app-tg-prod` (current production)
- **Green**: `app-tg-green-prod` (new deployment)

### AWS Resources
- S3 bucket for CodePipeline artifacts
- IAM roles for CodeBuild, CodePipeline, and CodeDeploy
- CloudWatch Event Rules for automation
- CodeDeploy ECS Blue-Green configuration

## Prerequisites

1. **GitHub Repository**: Code in GitHub at `gula123/setAdvancedApp`
2. **GitHub Personal Access Token**: Required for CodePipeline
3. **PROD Infrastructure**: Application deployed with `enable_blue_green_deployment = true`
4. **Two Target Groups**: Blue and green target groups must exist
5. **ECS Service**: Must use CODE_DEPLOY deployment controller

## Setup Instructions

### 1. Verify PROD Infrastructure

Ensure PROD environment has Blue-Green configuration:

```bash
cd terraform/tf-prod
grep "enable_blue_green_deployment" main.tf
# Should show: enable_blue_green_deployment = true
```

### 2. Create GitHub Token Variable

```bash
cd terraform/tf-cicd-prod
cat > terraform.tfvars <<EOF
github_token = "YOUR_GITHUB_PERSONAL_ACCESS_TOKEN"
EOF
```

### 3. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify Deployment

```bash
# Check CodeDeploy application
aws deploy get-application \
  --application-name setadvanced-app-prod \
  --region eu-north-1

# Check deployment group
aws deploy get-deployment-group \
  --application-name setadvanced-app-prod \
  --deployment-group-name setadvanced-deployment-group-prod \
  --region eu-north-1

# View target groups
aws elbv2 describe-target-groups \
  --names app-tg-prod app-tg-green-prod \
  --region eu-north-1
```

## Blue-Green Deployment Workflow

```
┌─────────────┐
│   GitHub    │ Push to main branch
│    (main)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  CI Build   │ Linting, tests, validation
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Deploy Build │ Build Docker, generate appspec.yaml & taskdef.json
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│         CodeDeploy Blue-Green Orchestration          │
├─────────────────────────────────────────────────────┤
│  1. Deploy to GREEN target group                     │
│     └─ New ECS tasks launched                        │
│  2. Health checks on GREEN                           │
│     └─ Verify new version is healthy                 │
│  3. Traffic shift: BLUE → GREEN                      │
│     └─ ALB instantly routes to GREEN                 │
│  4. Monitor deployment                               │
│     └─ Automatic rollback on failure                 │
│  5. Terminate BLUE tasks (after 5 min)              │
│     └─ Old version decommissioned                    │
└─────────────────────────────────────────────────────┘
```

## Configuration

### GitHub Settings
- **Owner**: `gula123`
- **Repository**: `setAdvancedApp`
- **Branch**: `main`

### AWS Settings
- **Region**: `eu-north-1`
- **ECS Cluster**: `app-cluster-prod`
- **ECS Service**: `app-service-prod`
- **Deployment Controller**: `CODE_DEPLOY`
- **ECR Repository**: `set/setadvancedrepository`

### Blue-Green Settings
- **Traffic Routing**: AllAtOnce (instant cutover)
- **Termination Wait**: 5 minutes
- **Auto Rollback**: Enabled on failure
- **Target Group Pair**: 
  - Production traffic: `app-tg-prod` (blue)
  - Test traffic: `app-tg-green-prod` (green)

## Outputs

After successful deployment:

```hcl
codepipeline_name = "setadvanced-pipeline-prod"
codepipeline_url = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/setadvanced-pipeline-prod/view"
ci_codebuild_project_name = "setadvanced-ci-prod"
deploy_codebuild_project_name = "setadvanced-deploy-prod"
codedeploy_application_name = "setadvanced-app-prod"
codedeploy_deployment_group_name = "setadvanced-deployment-group-prod"
artifacts_bucket_name = "setadvanced-codepipeline-artifacts-prod-XXXXXXXX"
```

## Deployment Process

### Automatic Deployment
1. Push code to `main` branch
2. Pipeline automatically triggers
3. CI build validates code
4. Deploy build creates container and deployment files
5. CodeDeploy performs Blue-Green deployment
6. Traffic automatically shifts to new version
7. Old version terminates after 5 minutes

### Monitoring Deployment

```bash
# List recent deployments
aws deploy list-deployments \
  --application-name setadvanced-app-prod \
  --deployment-group-name setadvanced-deployment-group-prod \
  --region eu-north-1

# Get deployment status
aws deploy get-deployment \
  --deployment-id <deployment-id> \
  --region eu-north-1

# Watch ECS service
aws ecs describe-services \
  --cluster app-cluster-prod \
  --services app-service-prod \
  --region eu-north-1
```

### View Logs

```bash
# CodeBuild CI logs
aws logs tail /aws/codebuild/setadvanced-ci-prod --follow

# CodeBuild Deploy logs
aws logs tail /aws/codebuild/setadvanced-deploy-prod --follow

# ECS application logs
aws logs tail /ecs/setAdvanced-app-prod --follow
```

## Rollback Strategy

### Automatic Rollback
CodeDeploy automatically rolls back if:
- New tasks fail health checks
- Deployment errors occur
- Tasks crash or become unhealthy

### Manual Rollback
```bash
# Stop ongoing deployment
aws deploy stop-deployment \
  --deployment-id <deployment-id> \
  --auto-rollback-enabled \
  --region eu-north-1

# Redeploy previous version
# Simply push previous commit to main branch
```

## Testing Blue-Green Deployment

### 1. Make a Code Change
```bash
# Update application code
git add .
git commit -m "Test Blue-Green deployment"
git push origin main
```

### 2. Monitor Pipeline
```bash
# Watch pipeline execution
aws codepipeline get-pipeline-state \
  --name setadvanced-pipeline-prod \
  --region eu-north-1
```

### 3. Watch Traffic Shift
- Navigate to ALB console
- Watch target groups switch
- Monitor health checks
- Observe zero downtime

## Troubleshooting

### Deployment Stuck
- Check ECS service events
- Verify security groups allow ALB → ECS traffic
- Check task definition validity
- Review CodeDeploy deployment logs

### Health Check Failures
- Verify application health endpoint: `/actuator/health`
- Check ALB target group health check configuration
- Review application logs for errors
- Ensure port 8080 is exposed

### Traffic Not Shifting
- Verify both target groups exist
- Check ALB listener configuration
- Review CodeDeploy deployment group settings
- Ensure ECS service uses CODE_DEPLOY controller

### Rollback Issues
- Check CodeDeploy deployment history
- Verify previous task definition exists
- Review IAM permissions for CodeDeploy

## Security Features

- ✅ GitHub token stored as sensitive variable
- ✅ IAM roles with least-privilege permissions
- ✅ Encrypted S3 bucket for artifacts
- ✅ No secrets in buildspec files
- ✅ Automatic rollback on security failures
- ✅ Zero-downtime for security patches

## Cost Considerations

- **CodePipeline**: $1/month per active pipeline
- **CodeBuild**: Pay per build minute (~$0.005/min)
- **CodeDeploy**: Free for ECS deployments
- **Additional ECS Tasks**: During deployment, both blue and green run briefly
- **S3 Artifacts**: Lifecycle policy deletes after 30 days

## Benefits of Blue-Green in PROD

✅ **Zero Downtime**: Users never experience service interruption  
✅ **Instant Rollback**: Switch back to blue if issues detected  
✅ **Safe Deployments**: Test green before routing traffic  
✅ **Automated Process**: No manual steps required  
✅ **Compliance**: Meets enterprise deployment standards  
✅ **Confidence**: Deploy production changes with safety net  

## Architecture Diagram

```
                    ┌──────────────┐
                    │   GitHub     │
                    │   (main)     │
                    └──────┬───────┘
                           │
                           ▼
                ┌──────────────────────┐
                │   CodePipeline       │
                │  Source → CI → Build │
                └──────────┬───────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │     CodeDeploy       │
                │   Blue-Green Mgr     │
                └──────────┬───────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐
    │  BLUE (Current) │       │ GREEN (New Ver) │
    │  app-tg-prod    │       │ app-tg-green    │
    │  Port 8080      │       │ Port 8080       │
    └────────┬────────┘       └────────┬────────┘
             │                         │
             └──────────┬──────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  ALB (app-lb-    │
              │      prod)        │
              └──────────────────┘
                        │
                        ▼
                   👥 Users
```

## Module 3 Compliance

✅ **CI/CD Pipeline**: Fully automated from commit to production  
✅ **Blue-Green Deployment**: Zero-downtime releases  
✅ **GitHub Integration**: Using GitHub (not CodeCommit)  
✅ **Automated Testing**: CI stage validates code  
✅ **Infrastructure as Code**: All resources in Terraform  
✅ **Production Ready**: Enterprise-grade deployment strategy  

This completes Module 3 requirements for the SET Advanced mentoring program.
