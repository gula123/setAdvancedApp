# CI/CD Pipeline Troubleshooting Guide

## Common Issues and Solutions

### 1. GitHub Token Issues

**Problem**: Pipeline fails to connect to GitHub
**Solution**: 
- Ensure your GitHub token has the correct permissions:
  - `repo` (Full control of private repositories)
  - `admin:repo_hook` (Full control of repository hooks)
- Token must not be expired
- Check `terraform.tfvars` has the correct token

### 2. ECR Repository Not Found

**Problem**: CodeBuild fails with ECR repository error
**Solution**: 
- Ensure ECR repository exists: `set/setadvancedrepository`
- Check the repository name in `main.tf`
- Verify AWS region is correct

### 3. ECS Service Not Found

**Problem**: Deployment fails with ECS service error
**Solution**:
- Ensure ECS cluster `app-cluster-dev` exists
- Ensure ECS service `app-service-dev` exists
- Deploy infrastructure from modules 1 & 2 first

### 4. Lambda Function Not Found

**Problem**: Lambda deployment fails
**Solution**:
- Ensure Lambda function `image-processing-lambda-dev` exists
- Check Lambda function name in configuration
- Verify Lambda function is in the same region

### 5. S3 Bucket Access Denied

**Problem**: CodeBuild can't upload to S3
**Solution**:
- Check S3 bucket `setadvanced-gula-dev` exists
- Verify CodeBuild IAM role has S3 permissions
- Check bucket region matches CodeBuild region

### 6. Blue-Green Deployment Issues

**Problem**: CodeDeploy blue-green deployment fails
**Solution**:
- Verify target group `app-tg-dev` exists
- Check ALB configuration
- Ensure ECS service uses the target group
- Verify task definition format in `taskdef.json`

## Pipeline Monitoring

### Check Pipeline Status
```bash
aws codepipeline get-pipeline-state --name setadvanced-pipeline-dev
```

### View CodeBuild Logs
1. Go to AWS CodeBuild console
2. Select your build project
3. Click on build history
4. View logs for failed builds

### Check ECS Service Status
```bash
aws ecs describe-services --cluster app-cluster-dev --services app-service-dev
```

### Monitor Lambda Function
```bash
aws lambda get-function --function-name image-processing-lambda-dev
```

## Debugging Commands

### Test GitHub Connection
```bash
# Test if GitHub token works
curl -H "Authorization: token YOUR_GITHUB_TOKEN" https://api.github.com/user
```

### Check ECR Repository
```bash
aws ecr describe-repositories --repository-names set/setadvancedrepository
```

### List ECS Resources
```bash
# List clusters
aws ecs list-clusters

# List services in cluster
aws ecs list-services --cluster app-cluster-dev

# Describe service
aws ecs describe-services --cluster app-cluster-dev --services app-service-dev
```

### Check Target Groups
```bash
aws elbv2 describe-target-groups --names app-tg-dev
```

## Log Locations

### CodeBuild Logs
- AWS Console: CodeBuild → Build Projects → Build History
- CloudWatch: `/aws/codebuild/setadvanced-ci-dev`
- CloudWatch: `/aws/codebuild/setadvanced-deploy-dev`

### CodePipeline Logs
- AWS Console: CodePipeline → Pipelines → Pipeline History
- CloudWatch Events for pipeline state changes

### ECS Logs
- CloudWatch: `/ecs/app-dev`
- Container logs from ECS tasks

## Performance Tips

### Speed Up Builds
1. Use smaller CodeBuild compute types for CI
2. Cache Maven dependencies
3. Optimize Docker image layers
4. Use multi-stage Docker builds

### Reduce Costs
1. Use appropriate CodeBuild compute sizes
2. Clean up old artifacts in S3
3. Monitor CloudWatch logs retention
4. Use spot instances for non-critical builds

## Security Best Practices

### Secrets Management
- Store GitHub token in AWS Secrets Manager
- Use IAM roles instead of access keys
- Enable MFA for AWS accounts
- Regularly rotate access tokens

### Network Security
- Run CodeBuild in private subnets
- Use VPC endpoints for AWS services
- Restrict security group access
- Enable VPC Flow Logs

## Blue-Green Deployment Workflow

### Manual Blue-Green Process
1. Deploy new version (Green)
2. Test Green environment
3. Switch traffic to Green
4. Monitor health checks
5. Terminate Blue if successful

### Automated Blue-Green with CodeDeploy
1. CodeDeploy creates Green environment
2. Health checks validate Green
3. Traffic shifts gradually
4. Blue environment terminated automatically

### Rollback Process
1. Detect deployment issues
2. Stop traffic to Green
3. Route traffic back to Blue
4. Investigate and fix issues
5. Redeploy when ready

## Contact and Support

For issues not covered in this guide:
1. Check AWS CloudTrail for API errors
2. Review IAM policies and permissions
3. Contact your mentor or peer reviewer
4. Submit support ticket with AWS if needed