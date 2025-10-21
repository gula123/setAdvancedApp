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
  - URL: http://app-lb-dev-345287946.eu-north-1.elb.amazonaws.com
  - VPC: 10.1.0.0/16
  - Resources: 52 active
- 🟡 **QA**: Ready for deployment
- 🟡 **PROD**: Ready for deployment

## 📋 Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform v1.0+
3. Access to AWS account with permissions for:
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

### High Availability
- **Multi-AZ deployment** across 2 availability zones
- **Auto Scaling** ECS service with desired capacity
- **Application Load Balancer** with health checks
- **Private subnet deployment** for enhanced security

## 📁 Project Structure

```
setAdvancedApp/
├── terraform/
│   ├── tf-backend/          # S3 + DynamoDB backend
│   ├── tf-dev/              # DEV environment
│   ├── tf-qa/               # QA environment
│   ├── tf-prod/             # PROD environment
│   └── modules/
│       ├── tf-environment/  # VPC, networking, core services
│       └── tf-application/  # ECS, ALB, application resources
├── src/                     # Java Spring Boot application
└── Dockerfile              # Container configuration
```

## 🔐 Security Features

- **Private subnets** for application workloads
- **VPC endpoints** eliminate internet traffic for AWS services
- **Security groups** with least privilege access
- **IAM roles** with minimal required permissions
- **Encrypted S3 bucket** for state storage

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