# SetAdvanced App - Module 2 - Terraform Infrastructure

This project implements a complete AWS infrastructure for an image recognition application using Terraform modules.

## Architecture Overview

The infrastructure is organized into two main modules:

1. **tf-environment**: Persistent infrastructure components
2. **tf-application**: Non-persistent application components

## Project Structure

```
terraform/
├── modules/
│   ├── tf-environment/          # Persistent infrastructure
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── datasources.tf
│   │   ├── s3_bucket.tf
│   │   ├── sns_topic.tf
│   │   ├── sqs.tf
│   │   ├── dynamodb.tf
│   │   ├── networking.tf
│   │   └── README.md
│   └── tf-application/          # Application infrastructure
│       ├── lambda/
│       │   └── index.py         # Lambda function code
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── datasources.tf
│       ├── lambda.tf
│       ├── load_balancer.tf
│       ├── ecs.tf
│       └── README.md
├── tf-dev/                      # Development environment
│   ├── main.tf
│   ├── versions.tf
│   └── README.md
├── tf-qa/                       # QA environment
│   ├── main.tf
│   ├── versions.tf
│   └── README.md
└── tf-prod/                     # Production environment
    ├── main.tf
    ├── versions.tf
    └── README.md
```

## Components

### tf-environment Module

**Persistent Infrastructure:**
- **S3 Bucket**: Stores uploaded images with public read access
- **DynamoDB Table**: Stores image recognition results (ImageName, LabelValue)
- **SNS Topic**: Receives S3 bucket notifications
- **SQS Queue**: Queues processing requests for Lambda
- **VPC Endpoints**: Secure connectivity (S3, ECR, DynamoDB, CloudWatch Logs)
- **Default Subnets**: Network infrastructure

### tf-application Module

**Application Infrastructure:**
- **Lambda Function**: Processes images using Amazon Rekognition
- **Application Load Balancer**: Distributes traffic to ECS tasks
- **ECS Cluster & Service**: Hosts containerized application
- **IAM Roles**: Execution and task roles for services
- **CloudWatch Log Groups**: Application logging

## Deployment Workflow

1. **Upload Image to S3** → Triggers SNS notification
2. **SNS** → Sends message to SQS queue
3. **SQS** → Triggers Lambda function
4. **Lambda** → Uses Rekognition to analyze image
5. **Lambda** → Stores results in DynamoDB

## Environment Configurations

### Development (tf-dev)
- Bucket: `setadvanced-app-images-dev`
- All resources tagged with `Environment = "dev"`

### QA (tf-qa)
- Bucket: `setadvanced-app-images-qa`
- All resources tagged with `Environment = "qa"`

### Production (tf-prod)
- Bucket: `setadvanced-app-images-prod`
- All resources tagged with `Environment = "prod"`

## Quick Start

1. **Initialize any environment:**
```bash
cd terraform/tf-dev  # or tf-qa, tf-prod
terraform init
```

2. **Plan deployment:**
```bash
terraform plan
```

3. **Deploy infrastructure:**
```bash
terraform apply
```

4. **Get outputs:**
```bash
terraform output
```

## Configuration Requirements

Before deployment, update the following in each environment's `main.tf`:

- Replace `image_uri = "nginx:latest"` with your actual ECR repository URI
- Configure remote state backend for production use
- Review security group configurations for production environments

## Key Features

- **Modular Design**: Reusable modules for different environments
- **Environment Isolation**: Separate resources per environment
- **Security**: VPC endpoints for secure AWS service communication
- **Scalability**: Auto-scaling ECS service with load balancer
- **Monitoring**: CloudWatch integration for logging
- **Event-Driven**: Automatic image processing via S3/SNS/SQS/Lambda

## Next Steps

1. Set up ECR repository and push your application image
2. Configure remote state storage (S3 backend)
3. Set up CI/CD pipeline for automated deployments
4. Configure monitoring and alerting
5. Implement proper backup and disaster recovery procedures