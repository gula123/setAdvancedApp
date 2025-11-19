update
# setAdvancedApp

Advanced AWS ECS Application with Separate VPC Architecture per Environment

## 🏗️ Architecture Overview

This project implements a **separate VPC architecture** for each environment (DEV, QA, PROD) to provide maximum isolation and security.

### Network Architecture
- **DEV Environment**: VPC `10.1.0.0/16`
- **QA Environment**: VPC `10.2.0.0/16`  
- **PROD Environment**: VPC `10.3.0.0/16`

Each VPC includes:
- Public subnets for load balancers
- Private subnets for ECS tasks
- VPC endpoints for AWS services (ECR, CloudWatch Logs, S3, DynamoDB)
- NAT Gateway for outbound internet access

## 🚀 Deployment Status

### Backend Infrastructure
- ✅ **S3 Backend**: `setadvanced-terraform-state` (Active)
- ✅ **DynamoDB Lock**: `terraform-state-lock` (Active)
- ✅ **Remote State**: Configured for all environments

### Environment Status
- ✅ **DEV**: **DEPLOYED** 
  - VPC: 10.1.0.0/16
  - Deployment: ECS Rolling Update
  - CI/CD: ✅ Active (GitHub → CodePipeline)
- ✅ **QA**: **DEPLOYED**
  - VPC: 10.2.0.0/16
  - Deployment: ECS Rolling Update
  - CI/CD: ✅ Active (GitHub → CodePipeline)
- ✅ **PROD**: **DEPLOYED**
  - VPC: 10.3.0.0/16
  - Deployment: Blue-Green (Zero Downtime)
  - CI/CD: ✅ Active (GitHub → CodePipeline → CodeDeploy)

### CI/CD Pipelines (Module 3) - GitFlow Strategy
- ✅ **DEV Pipeline**: `setadvanced-pipeline-dev` (develop branch → ECS Rolling Update)
  - Trigger: GitHub OAuth polling (automatic on push)
  - Stages: Source → CI Build → Deploy → Infrastructure Tests → API Integration Tests
- ✅ **QA Pipeline**: `setadvanced-pipeline-qa` (release/** pattern → ECS Rolling Update)
  - Trigger: GitHub v2 (CodeStar Connections) with wildcard branch pattern support
  - Auto-triggers on any release/* branch creation or push
  - Stages: Source → CI Build → Deploy → Infrastructure Tests → API Integration Tests
- ✅ **PROD Pipeline**: `setadvanced-pipeline-prod` (main branch → Blue-Green Deployment)
  - Trigger: GitHub OAuth polling (automatic on push)
  - Stages: Source → CI Build → Deploy (Blue-Green via CodeDeploy) → Infrastructure Tests → API Integration Tests
  - Zero-downtime deployment with ECS Blue-Green target groups
  - ALB traffic shifting managed by CodeDeploy

## 📋 Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform v1.0+
3. **Checkov** for security compliance scanning:
   ```bash
   # Install via pip
   pip install checkov
   
   # Or via conda
   conda install -c conda-forge checkov
   
   # Or via brew (macOS)
   brew install checkov
   ```
4. **TFLint** for Terraform code quality:
   ```bash
   # Install via curl
   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
   ```
5. **TFSec** for static security analysis:
   ```bash
   # Install via Go
   go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
   
   # Or via brew (macOS)
   brew install tfsec
   
   # Or download binary from GitHub releases
   # https://github.com/aquasecurity/tfsec/releases
   ```
6. Access to AWS account with permissions for:
   - VPC, EC2, ECS, ALB
   - S3, DynamoDB
   - IAM roles and policies
   - CloudWatch Logs

## 🛠️ Initial Setup

### 1. Deploy Backend Infrastructure

```bash
cd terraform/tf-backend
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket for state storage with versioning and encryption
- DynamoDB table for state locking

### 2. Environment Deployment

#### Deploy DEV Environment
```bash
cd terraform/tf-dev
terraform init
terraform plan
terraform apply
```

#### Deploy QA Environment
```bash
cd terraform/tf-qa  
terraform init
terraform plan
terraform apply
```

#### Deploy PROD Environment
```bash
cd terraform/tf-prod
terraform init
terraform plan
terraform apply
```

### 3. CI/CD Pipeline Deployment (Module 3) - GitFlow

#### Prerequisites
- GitHub personal access token with repo permissions (stored in AWS Secrets Manager or OAuth)
- Application infrastructure deployed (DEV/QA/PROD)
- GitHub repository: https://github.com/gula123/setAdvancedApp
- GitFlow branches: `develop`, `release/*`, `main`

#### GitFlow Branch Strategy
This project uses GitFlow for environment promotion:

1. **Feature Development** → `feature/*` branches
   - Create from `develop`
   - Open PR to `develop` for review
   - PR triggers Terraform validation (static checks only, no deployment)
   
2. **Development Environment** → `develop` branch
   - Merge approved PRs from `feature/*` branches
   - Automatic deployment to DEV environment
   - Pipeline: CI Build → Deploy → Infrastructure Tests → API Integration Tests
   
3. **QA Environment** → `release/*` branches
   - Create from `develop` when ready for QA testing (e.g., `release/1.0.0`)
   - Automatic deployment to QA environment (GitHub v2 CodeStar Connections with wildcard pattern)
   - Pipeline auto-triggers within ~1 minute of branch creation/push
   - Pipeline: CI Build → Deploy → Infrastructure Tests → API Integration Tests
   
4. **Production Environment** → `main` branch
   - Merge from `release/*` branches after QA approval
   - Automatic Blue-Green deployment to PROD (GitHub OAuth polling)
   - Pipeline: CI Build → Deploy (Blue-Green via CodeDeploy) → Infrastructure Tests → API Integration Tests
   - Zero-downtime deployment with ECS Blue/Green target groups
   - ALB traffic shifting managed by CodeDeploy

#### Deploy DEV CI/CD Pipeline (develop branch)
```bash
cd terraform/tf-cicd-dev
# GitHub OAuth token will be configured via aws_codebuild_source_credential
terraform init
terraform apply
```

**Configuration:**
- Branch: `develop`
- Deployment: ECS Rolling Update
- PR Validation: Enabled (terraform/checkov/tflint)
- Stages: Source → CI → Deploy → Infrastructure Tests → API Tests

#### Deploy QA CI/CD Pipeline (release/** branches)
```bash
cd terraform/tf-cicd-qa
terraform init
terraform apply
```

**Configuration:**
- Branch Pattern: `release/**` (wildcard pattern support via GitHub v2 CodeStar Connections)
- Deployment: ECS Rolling Update
- Pipeline Type: V2 with execution mode QUEUED (required for trigger filters)
- GitHub Integration: CodeStar Connection (not OAuth - supports branch patterns)
- Auto-triggers: ~1 minute after push to any release/* branch
- Stages: Source → CI → Deploy → Infrastructure Tests → API Tests

#### Deploy PROD CI/CD Pipeline (main branch, Blue-Green)
```bash
cd terraform/tf-cicd-prod
terraform init
terraform apply
```

**Configuration:**
- Branch: `main`
- Deployment: Blue-Green (Zero-Downtime) via CodeDeploy
- Deployment Controller: CODE_DEPLOY (not ECS)
- Blue/Green Target Groups: `app-tg-prod` (blue) and `app-tg-green-prod` (green)
- Traffic Shifting: Managed by CodeDeploy via ALB listener rules
- Health Checks: ECS task health + ALB target group health
- Stages: Source → CI → Deploy (Blue-Green) → Infrastructure Tests → API Tests
- Auto-triggers: ~1 minute after push to main branch (GitHub OAuth polling)

## 🔄 GitFlow Development Workflow

### Daily Development Process

1. **Create Feature Branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-new-feature
   ```

2. **Develop and Test Locally**
   ```bash
   # Make changes
   ./mvnw clean test
   git add .
   git commit -m "Add new feature"
   git push origin feature/my-new-feature
   ```

3. **Open Pull Request to develop**
   - PR automatically triggers Terraform validation
   - Checks: `terraform fmt`, `terraform validate`, `checkov`, `tflint`
   - GitHub status checks must pass before merge
   - Review and approval required

4. **Merge to develop → DEV Deployment**
   ```bash
   # After PR approval
   git checkout develop
   git merge feature/my-new-feature
   git push origin develop
   ```
   - Automatic trigger: DEV pipeline starts
   - Pipeline stages: CI Build → Deploy → Infrastructure Tests → API Tests
   - Monitor in CodePipeline console

5. **Create Release Branch for QA**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/1.0.0
   git push origin release/1.0.0
   ```
   - Automatic trigger: QA pipeline starts
   - Same pipeline stages as DEV
   - QA testing and validation

6. **Merge to main → PROD Deployment**
   ```bash
   # After QA approval, open PR from release/1.0.0 to main
   # PR triggers Terraform validation (no deployment)
   # After PR approval and merge:
   git checkout main
   git merge release/1.0.0
   git push origin main
   ```
   - Automatic trigger: PROD pipeline starts (Blue-Green)
   - Zero-downtime deployment
   - Automatic rollback on failure
   - Monitor in CodePipeline and CodeDeploy consoles

## 🔧 Key Features

### Separate VPC Architecture
- **Complete isolation** between environments
- **Dedicated networking** for each environment
- **Independent security groups** and routing
- **VPC endpoints** for private AWS service access

### Remote State Management
- **S3 backend** with encryption and versioning
- **DynamoDB state locking** prevents concurrent modifications
- **Separate state files** per environment
- **State isolation** ensures environment independence

### Code Quality & Security Validation
- **TFLint integration** for Terraform best practices and code quality
- **Checkov security scanning** for compliance validation and policy enforcement
- **TFSec static analysis** for security vulnerability detection
- **Multi-tool validation** with 100% compliance across all scanners
- **Automated linting** with terraform ruleset
- **Configuration validation** before deployment
- **Centralized security configuration** with documented suppressions

### High Availability
- **Multi-AZ deployment** across 2 availability zones
- **Auto Scaling** ECS service with desired capacity
- **Application Load Balancer** with health checks
- **Private subnet deployment** for enhanced security

### CI/CD Automation (Module 3) - GitFlow Workflow
- **GitFlow Branching Strategy**
  - `develop` branch → DEV environment (automatic deployment)
  - `release/*` branches → QA environment (automatic deployment)
  - `main` branch → PROD environment (Blue-Green deployment)
- **Pull Request Validation** (automatic on PR creation/update)
  - Terraform format check (`terraform fmt`)
  - Terraform validation (`terraform validate`)
  - Security compliance scanning (Checkov with documented exceptions)
  - Code quality linting (TFLint errors-only mode)
  - GitHub status checks block merge if validation fails
- **CI Build Stage** (unit tests before deployment)
  - Maven compile with JaCoCo code coverage
  - Unit tests only (excludes integration/controller tests)
  - Fast feedback loop (~1-2 minutes)
- **Deployment Stage**
  - Container build & push to Amazon ECR
  - ECS task definition update
  - Rolling updates (DEV/QA) or Blue-Green (PROD)
- **Infrastructure Tests Stage** (post-deployment validation)
  - ECS service health checks
  - Target group health verification
  - ALB connectivity tests
  - Application endpoint validation
- **API Integration Tests Stage** (all environments)
  - Controller endpoint tests
  - Image upload/download/search operations
  - DynamoDB integration verification
  - S3 integration verification

## 📁 Project Structure

```
setAdvancedApp/
├── terraform/
│   ├── .tflint.hcl                       # TFLint configuration for code quality
│   ├── .checkov.yml                      # Checkov security configuration (centralized)
│   ├── tf-backend/                       # S3 + DynamoDB backend
│   ├── tf-dev/                           # DEV environment (10.1.0.0/16)
│   ├── tf-qa/                            # QA environment (10.2.0.0/16)
│   ├── tf-prod/                          # PROD environment (10.3.0.0/16)
│   ├── tf-cicd-dev/                      # CI/CD pipeline for DEV (develop branch)
│   ├── tf-cicd-qa/                       # CI/CD pipeline for QA (release/* branches)
│   ├── tf-cicd-prod/                     # CI/CD pipeline for PROD (main branch)
│   └── modules/
│       ├── tf-environment/               # VPC, networking, core services
│       ├── tf-application/               # ECS, ALB, application resources
│       └── tf-cicd/                      # CodePipeline, CodeBuild, CodeDeploy, GitHub webhook
├── src/                                  # Java Spring Boot application
├── Dockerfile                            # Container configuration
├── buildspec-ci.yml                      # CI Build: unit tests, compile
├── buildspec-deploy.yml                  # Deployment: Docker build, ECR push, ECS update
├── buildspec-terraform-validate.yml      # PR Validation: terraform/checkov/tflint
├── buildspec-infrastructure-tests.yml    # Infrastructure Tests: post-deployment validation
└── buildspec-integration-tests.yml       # API Integration Tests: controller endpoint tests
```

## 🔐 Security Features

- **Private subnets** for application workloads
- **VPC endpoints** eliminate internet traffic for AWS services
- **Security groups** with least privilege access
- **IAM roles** with minimal required permissions
- **Encrypted S3 bucket** for state storage

### 🛡️ Multi-Tool Security Validation

This infrastructure achieves **100% security compliance** across multiple enterprise-grade security scanners:

#### 1. Code Quality Validation (TFLint)
```bash
# Navigate to terraform directory
cd terraform

# Initialize TFLint plugins (one time setup)
tflint --init

# Validate ALL configurations recursively
tflint --recursive
```

#### 2. Compliance Scanning (Checkov)
```bash
# Navigate to terraform directory
cd terraform

# Run security compliance scan
checkov -d . --quiet

# Run detailed security scan with all findings
checkov -d . --compact

# Run scan for specific framework
checkov -d . --framework terraform --quiet
```

#### 3. Static Security Analysis (TFSec)
```bash
# Navigate to terraform directory
cd terraform

# Run static security analysis
tfsec . --config-file .tfsec.yml

# Run with specific severity levels
tfsec . --minimum-severity MEDIUM

# Output results in different formats
tfsec . --format json
tfsec . --format sarif
```

#### Comprehensive Security Achievements
- ✅ **TFLint**: 100% code quality validation - Zero issues
- ✅ **Checkov**: 378 security checks passed (100% compliance)
- ✅ **TFSec**: 593 security checks passed, 31 documented suppressions
- ✅ **Enterprise-grade encryption** with customer-managed KMS keys
- ✅ **WAF protection** with Log4j vulnerability shields
- ✅ **VPC Flow Logs** with 1-year retention
- ✅ **S3 security hardening** with versioning, lifecycle, and access logging
- ✅ **DynamoDB encryption** with point-in-time recovery
- ✅ **HTTPS enforcement** across all environments
- ✅ **IAM least-privilege** policies with no wildcard permissions
- ✅ **Comprehensive audit logging** with KMS encryption

#### Security Configuration Management
All security exceptions are centrally managed and documented:
- **Checkov suppressions**: `.checkov.yml` with detailed justifications
- **TFSec suppressions**: Inline `#tfsec:ignore:` comments with reasoning
- **Intentional design decisions**: HTTP redirect, SSL termination patterns
- **Cost-conscious choices**: Optional expensive features (cross-region replication)
- **Enterprise audit compliance**: All suppressions documented for security reviews

## 🌐 VPC Endpoints

Each environment includes dedicated VPC endpoints:
- **ECR API & DKR**: Container image pulling
- **CloudWatch Logs**: Log streaming
- **S3**: Object storage access
- **DynamoDB**: Database access

## 📊 Monitoring & Logging

- **CloudWatch Logs** for application and ECS logs
- **Application Load Balancer** access logs
- **VPC Flow Logs** (can be enabled per environment)
- **CloudWatch Metrics** for ECS and ALB

## 🚨 Troubleshooting

### Common Issues

1. **State Lock Error**
   ```bash
   # Force unlock if needed (use carefully)
   terraform force-unlock <LOCK_ID>
   ```

2. **VPC Endpoint DNS Issues**
   - Verify `private_dns_enabled = true` in endpoint configuration
   - Check security group allows port 443

3. **ECS Task Launch Issues**
   - Verify VPC endpoints are accessible
   - Check IAM roles have required permissions
   - Review CloudWatch logs for errors

### Comprehensive Validation Commands

```bash
# Navigate to terraform directory (REQUIRED)
cd terraform

# 1. CODE QUALITY (TFLint)
# Initialize TFLint plugins (one time setup)
tflint --init

# Validate ALL Terraform configurations recursively
tflint --recursive

# 2. COMPLIANCE SCANNING (Checkov)
# Run security compliance scan
checkov -d . --quiet

# 3. STATIC SECURITY ANALYSIS (TFSec)
# Run static security analysis
tfsec .

# 4. TERRAFORM VALIDATION
# Format Terraform code
terraform fmt -recursive .

# Validate syntax for specific environments
cd tf-dev && terraform validate
cd ../tf-qa && terraform validate  
cd ../tf-prod && terraform validate
```

#### Quick Multi-Tool Validation Script
```bash
#!/bin/bash
cd terraform

echo "🔧 Running TFLint..."
tflint --recursive && echo "✅ TFLint: PASSED" || echo "❌ TFLint: FAILED"

echo "🛡️ Running Checkov..."
checkov -d . --quiet && echo "✅ Checkov: PASSED" || echo "❌ Checkov: FAILED"

echo "🔒 Running TFSec..."
tfsec . && echo "✅ TFSec: PASSED" || echo "❌ TFSec: FAILED"

echo "⚙️ Running Terraform validation..."
for env in tf-dev tf-qa tf-prod; do
  cd $env && terraform validate && echo "✅ $env: PASSED" || echo "❌ $env: FAILED"
  cd ..
done
```

#### Maven Infrastructure Testing
```bash
# Run all infrastructure tests
mvn test -Dtest=*InfrastructureTest

# Run only DEV infrastructure test
mvn test -Dtest=DevInfrastructureTest

# Run only QA infrastructure test
mvn test -Dtest=QAInfrastructureTest

# Run only PROD infrastructure test
mvn test -Dtest=ProdInfrastructureTest
```

### Useful Commands

```bash
# Check backend state
aws s3 ls s3://setadvanced-terraform-state/environments/

# View DynamoDB locks
aws dynamodb scan --table-name terraform-state-lock

# ECS service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Application logs
aws logs tail /ecs/setAdvanced-app-<env> --follow
```

## 🔄 Environment Management

### Scaling Environments

Each environment can be scaled independently by modifying:
- ECS service `desired_count`
- ALB target group configuration
- Auto Scaling policies

### Environment Destruction

```bash
# Destroy specific environment
cd terraform/tf-<env>
terraform destroy

# Destroy backend (only after all environments destroyed)
cd terraform/tf-backend
terraform destroy
```

## 📝 Notes

- State files are stored as `environments/<env>/terraform.tfstate`
- Each environment uses separate AWS resources
- DynamoDB state locking prevents concurrent operations
- VPC peering can be added for cross-environment communication if needed

## 🆘 Support

For issues or questions:
1. Check CloudWatch Logs for application errors
2. Review Terraform plan output before applying
3. Verify AWS credentials and permissions
4. Check VPC endpoint connectivity for AWS services
