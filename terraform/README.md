# SET Advanced App - Terraform Infrastructure# SET Advanced App - Terraform Infrastructure



## 🏗️ Architecture Overview## 🏗️ Architecture Overview



This project implements a **separate VPC per environment** architecture for AWS ECS Fargate applications, ensuring complete isolation between DEV, QA, and PROD environments.This project implements a **separate VPC per environment** architecture for AWS ECS Fargate applications, ensuring complete isolation between DEV, QA, and PROD environments.



### 🌐 Network Architecture### 🌐 Network Architecture



``````

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐

│   DEV VPC       │  │   QA VPC        │  │   PROD VPC      ││   DEV VPC       │  │   QA VPC        │  │   PROD VPC      │

│  10.1.0.0/16    │  │  10.2.0.0/16    │  │  10.3.0.0/16    ││  10.1.0.0/16    │  │  10.2.0.0/16    │  │  10.3.0.0/16    │

├─────────────────┤  ├─────────────────┤  ├─────────────────┤├─────────────────┤  ├─────────────────┤  ├─────────────────┤

│ Public Subnets  │  │ Public Subnets  │  │ Public Subnets  ││ Public Subnets  │  │ Public Subnets  │  │ Public Subnets  │

│ - ALB           │  │ - ALB           │  │ - ALB           ││ - ALB           │  │ - ALB           │  │ - ALB           │

│ - NAT Gateway   │  │ - NAT Gateway   │  │ - NAT Gateway   ││ - NAT Gateway   │  │ - NAT Gateway   │  │ - NAT Gateway   │

├─────────────────┤  ├─────────────────┤  ├─────────────────┤├─────────────────┤  ├─────────────────┤  ├─────────────────┤

│ Private Subnets │  │ Private Subnets │  │ Private Subnets ││ Private Subnets │  │ Private Subnets │  │ Private Subnets │

│ - ECS Tasks     │  │ - ECS Tasks     │  │ - ECS Tasks     ││ - ECS Tasks     │  │ - ECS Tasks     │  │ - ECS Tasks     │

│ - VPC Endpoints │  │ - VPC Endpoints │  │ - VPC Endpoints ││ - VPC Endpoints │  │ - VPC Endpoints │  │ - VPC Endpoints │

└─────────────────┘  └─────────────────┘  └─────────────────┘└─────────────────┘  └─────────────────┘  └─────────────────┘

``````



### 🔧 Infrastructure Components### 🔧 Infrastructure Components



**Per Environment:****Per Environment:**

- **VPC**: Dedicated network isolation- **VPC**: Dedicated network isolation

- **Public Subnets**: Internet-facing Application Load Balancer- **Public Subnets**: Internet-facing Application Load Balancer

- **Private Subnets**: ECS Fargate tasks (no public IP)- **Private Subnets**: ECS Fargate tasks (no public IP)

- **NAT Gateway**: Outbound internet access for private subnets- **NAT Gateway**: Outbound internet access for private subnets

- **VPC Endpoints**: Private connectivity to AWS services- **VPC Endpoints**: Private connectivity to AWS services

  - ECR API & DKR (Container registry)  - ECR API & DKR (Container registry)

  - CloudWatch Logs  - CloudWatch Logs

  - S3 (Gateway endpoint)  - S3 (Gateway endpoint)

  - DynamoDB (Gateway endpoint)  - DynamoDB (Gateway endpoint)

- **Security Groups**: Least-privilege network access- **Security Groups**: Least-privilege network access

- **S3 Bucket**: Image storage with notifications- **S3 Bucket**: Image storage with notifications

- **DynamoDB**: Image recognition results- **DynamoDB**: Image recognition results

- **SNS/SQS**: Event-driven processing- **SNS/SQS**: Event-driven processing

- **Lambda**: Image processing function- **Lambda**: Image processing function



## 📁 Project Structure## Project Structure



``````

terraform/terraform/

├── README.md                    # This file├── modules/

├── modules/│   ├── tf-environment/          # Persistent infrastructure

│   ├── tf-environment/         # Environment infrastructure│   │   ├── main.tf

│   │   ├── networking.tf       # VPC, subnets, endpoints│   │   ├── variables.tf

│   │   ├── s3_bucket.tf       # S3 storage│   │   ├── outputs.tf

│   │   ├── dynamodb.tf        # DynamoDB table│   │   ├── versions.tf

│   │   ├── sns_topic.tf       # SNS notifications│   │   ├── datasources.tf

│   │   ├── sqs.tf             # SQS queue│   │   ├── s3_bucket.tf

│   │   ├── variables.tf       # Module inputs│   │   ├── sns_topic.tf

│   │   └── outputs.tf         # Module outputs│   │   ├── sqs.tf

│   └── tf-application/         # Application infrastructure│   │   ├── dynamodb.tf

│       ├── ecs.tf             # ECS cluster and service│   │   ├── networking.tf

│       ├── load_balancer.tf   # ALB configuration│   │   └── README.md

│       ├── lambda.tf          # Image processing function│   └── tf-application/          # Application infrastructure

│       ├── variables.tf       # Module inputs│       ├── lambda/

│       └── outputs.tf         # Module outputs│       │   └── index.py         # Lambda function code

├── tf-backend/                 # Remote state infrastructure│       ├── main.tf

│   ├── main.tf                # S3 + DynamoDB for state│       ├── variables.tf

│   └── outputs.tf             # Backend configuration│       ├── outputs.tf

├── tf-dev/                     # DEV environment│       ├── versions.tf

│   ├── main.tf                # Environment configuration│       ├── datasources.tf

│   └── versions.tf            # Provider versions│       ├── lambda.tf

├── tf-qa/                      # QA environment│       ├── load_balancer.tf

│   ├── main.tf                # Environment configuration│       ├── ecs.tf

│   └── versions.tf            # Provider versions│       └── README.md

└── tf-prod/                    # PROD environment├── tf-dev/                      # Development environment

    ├── main.tf                # Environment configuration│   ├── main.tf

    └── versions.tf            # Provider versions│   ├── versions.tf

```│   └── README.md

├── tf-qa/                       # QA environment

## 🚀 Deployment Guide│   ├── main.tf

│   ├── versions.tf

### Prerequisites│   └── README.md

└── tf-prod/                     # Production environment

1. **AWS CLI** configured with appropriate permissions    ├── main.tf

2. **Terraform** >= 1.0 installed    ├── versions.tf

3. **Docker** for local container builds (optional)    └── README.md

```

### Initial Setup - Remote State Backend

## Components

First, create the shared S3 backend for state management:

### tf-environment Module

```powershell

# Deploy backend infrastructure**Persistent Infrastructure:**

cd terraform/tf-backend- **S3 Bucket**: Stores uploaded images with public read access

terraform init- **DynamoDB Table**: Stores image recognition results (ImageName, LabelValue)

terraform apply- **SNS Topic**: Receives S3 bucket notifications

- **SQS Queue**: Queues processing requests for Lambda

# Note the outputs - you'll need these for environment configuration- **VPC Endpoints**: Secure connectivity (S3, ECR, DynamoDB, CloudWatch Logs)

terraform output- **Default Subnets**: Network infrastructure

```

### tf-application Module

### Environment Configuration

**Application Infrastructure:**

Each environment uses dedicated CIDR blocks:- **Lambda Function**: Processes images using Amazon Rekognition

- **DEV**: `10.1.0.0/16`- **Application Load Balancer**: Distributes traffic to ECS tasks

- **QA**: `10.2.0.0/16`  - **ECS Cluster & Service**: Hosts containerized application

- **PROD**: `10.3.0.0/16`- **IAM Roles**: Execution and task roles for services

- **CloudWatch Log Groups**: Application logging

### Deploy Individual Environment

## Deployment Workflow

```powershell

# Navigate to desired environment1. **Upload Image to S3** → Triggers SNS notification

cd terraform/tf-dev  # or tf-qa, tf-prod2. **SNS** → Sends message to SQS queue

3. **SQS** → Triggers Lambda function

# Initialize Terraform with remote backend4. **Lambda** → Uses Rekognition to analyze image

terraform init5. **Lambda** → Stores results in DynamoDB



# Review planned changes## Environment Configurations

terraform plan

### Development (tf-dev)

# Apply infrastructure- Bucket: `setadvanced-app-images-dev`

terraform apply- All resources tagged with `Environment = "dev"`



# Get load balancer URL### QA (tf-qa)

terraform output load_balancer_url- Bucket: `setadvanced-app-images-qa`

```- All resources tagged with `Environment = "qa"`



### Deploy All Environments Simultaneously### Production (tf-prod)

- Bucket: `setadvanced-app-images-prod`

Thanks to separate VPCs, all environments can run concurrently:- All resources tagged with `Environment = "prod"`



```powershell## Quick Start

# Terminal 1 - DEV

cd terraform/tf-dev1. **Initialize any environment:**

terraform apply -auto-approve```bash

cd terraform/tf-dev  # or tf-qa, tf-prod

# Terminal 2 - QA  terraform init

cd terraform/tf-qa```

terraform apply -auto-approve

2. **Plan deployment:**

# Terminal 3 - PROD```bash

cd terraform/tf-prodterraform plan

terraform apply -auto-approve```

```

3. **Deploy infrastructure:**

### Destroy Environment```bash

terraform apply

```powershell```

cd terraform/tf-[environment]

terraform destroy -auto-approve4. **Get outputs:**

``````bash

terraform output

## 🔒 Security Features```



### Network Security## Configuration Requirements

- **Private ECS Tasks**: No public IP addresses

- **VPC Endpoints**: Traffic to AWS services stays within VPCBefore deployment, update the following in each environment's `main.tf`:

- **Security Groups**: Least-privilege access rules

- **NAT Gateway**: Controlled outbound internet access- Replace `image_uri = "nginx:latest"` with your actual ECR repository URI

- Configure remote state backend for production use

### Data Security- Review security group configurations for production environments

- **S3 Encryption**: Server-side encryption enabled

- **Remote State**: Encrypted S3 backend with DynamoDB locking## Key Features

- **IAM Roles**: Least-privilege service permissions

- **Modular Design**: Reusable modules for different environments

## 📊 Monitoring & Observability- **Environment Isolation**: Separate resources per environment

- **Security**: VPC endpoints for secure AWS service communication

### Health Checks- **Scalability**: Auto-scaling ECS service with load balancer

- **ALB Health Check**: `/actuator/health`- **Monitoring**: CloudWatch integration for logging

- **ECS Service Health**: Automatic task replacement- **Event-Driven**: Automatic image processing via S3/SNS/SQS/Lambda

- **CloudWatch Logs**: Centralized application logging

## Next Steps

### Endpoints

```1. Set up ECR repository and push your application image

# Health check2. Configure remote state storage (S3 backend)

GET http://app-lb-{env}-{id}.{region}.elb.amazonaws.com/actuator/health3. Set up CI/CD pipeline for automated deployments

4. Configure monitoring and alerting

# Image upload5. Implement proper backup and disaster recovery procedures
POST http://app-lb-{env}-{id}.{region}.elb.amazonaws.com/image
```

## 💰 Cost Optimization

### Cost Components (per environment)
- **NAT Gateway**: ~$45/month + data transfer
- **VPC Endpoints**: ~$7/month each (4 endpoints = $28/month)
- **ECS Fargate**: Pay per vCPU/memory usage
- **ALB**: ~$22/month + LCU usage

### Cost Reduction Tips
```powershell
# Destroy non-production environments when not needed
cd terraform/tf-dev
terraform destroy -auto-approve

# Scale down ECS desired count for development
# Edit main.tf: desired_count = 1 (instead of 2)
```

## 🔧 Troubleshooting

### Common Issues

**ECS Tasks Not Starting**
```powershell
# Check ECS service events
aws ecs describe-services --cluster app-cluster-{env} --services app-service-{env}

# Check VPC endpoint connectivity
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids {endpoint-id}
```

**ALB Health Check Failures**
```powershell
# Verify security group rules
aws ec2 describe-security-groups --group-ids {sg-id}

# Check target group health
aws elbv2 describe-target-health --target-group-arn {target-group-arn}
```

**Image Upload Failures**
```powershell
# Test S3 bucket access
aws s3 ls s3://setadvanced-gula-{env}

# Check SNS/SQS integration
aws sns list-subscriptions-by-topic --topic-arn {topic-arn}
```

## 🔄 Remote State Management

### S3 Backend Configuration
Each environment uses a separate state file in the shared S3 bucket:
- **DEV**: `dev/terraform.tfstate`
- **QA**: `qa/terraform.tfstate`
- **PROD**: `prod/terraform.tfstate`

### DynamoDB State Locking
- **Table**: `terraform-state-lock`
- **Primary Key**: `LockID`
- **Purpose**: Prevents concurrent Terraform operations

### State Commands
```powershell
# List remote state
terraform state list

# Show specific resource
terraform state show module.application.aws_lb.app_load_balancer

# Import existing resource
terraform import module.environment.aws_vpc.main vpc-12345678
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Plan
        run: |
          cd terraform/tf-dev
          terraform init
          terraform plan
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
```

## 📝 Development Workflow

1. **Make Changes**: Modify Terraform configurations
2. **Plan**: Run `terraform plan` to review changes
3. **Apply**: Deploy with `terraform apply`
4. **Test**: Verify application functionality
5. **Commit**: Version control your infrastructure changes

## 🆘 Emergency Procedures

### Rollback Deployment
```powershell
# Revert to previous Terraform state
terraform apply -target=module.application.aws_ecs_service.app_service

# Or destroy and redeploy
terraform destroy -target=module.application
terraform apply -target=module.application
```

### State Recovery
```powershell
# Pull latest state from S3
terraform refresh

# Force unlock state (if locked)
terraform force-unlock {lock-id}

# Backup current state
terraform state pull > backup.tfstate
```

### Access ECS Tasks
```powershell
# Enable ECS Exec for debugging
aws ecs update-service --cluster app-cluster-{env} --service app-service-{env} --enable-execute-command

# Execute commands in running task
aws ecs execute-command --cluster app-cluster-{env} --task {task-id} --container app-container --interactive --command "/bin/bash"
```

---

**🎯 Key Benefits of This Architecture:**
- ✅ **Complete Environment Isolation**: No resource conflicts
- ✅ **Simultaneous Deployment**: All environments can run together
- ✅ **Security**: Private subnets + VPC endpoints
- ✅ **Scalability**: Independent scaling per environment
- ✅ **State Management**: Centralized S3 backend with locking
- ✅ **Cost Control**: Destroy unused environments easily