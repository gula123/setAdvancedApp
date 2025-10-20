# Production Environment

This is the production environment configuration for the image recognition application.

## Quick Start

1. Initialize Terraform:
```bash
terraform init
```

2. Plan the deployment:
```bash
terraform plan
```

3. Apply the infrastructure:
```bash
terraform apply
```

4. Get outputs:
```bash
terraform output
```

## Resources

This configuration creates:
- All persistent infrastructure via the `tf-environment` module
- All application infrastructure via the `tf-application` module
- Resources are tagged with `Environment = "prod"`

## Configuration

- **S3 Bucket**: `setadvanced-app-images-prod-{random-suffix}`
- **DynamoDB Table**: `image-recognition-results-prod`
- **SNS Topic**: `image-notification-topic-prod`
- **SQS Queue**: `image-processing-queue-prod`
- **Application Port**: 8080
- **Container Image**: Replace `nginx:latest` with your actual ECR URI

## Outputs

- `load_balancer_url`: Public URL to access the application
- `s3_bucket_name`: Name of the S3 bucket for image uploads
- `dynamodb_table_name`: Name of the DynamoDB table

## Remote State

Configure remote state storage by adding a backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "environments/prod/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Production Considerations

- Review and adjust resource sizing for production workloads
- Configure proper backup and disaster recovery
- Set up monitoring and alerting
- Implement proper security controls
- Configure SSL/TLS certificates for the load balancer