# Terraform Backend Infrastructure

This folder contains Terraform configuration to create the **backend infrastructure** needed for remote state management of your other Terraform configurations.

## What this creates:

1. **S3 Bucket** (`setadvanced-terraform-state`):
   - ✅ Versioning enabled (state history)
   - ✅ Encryption enabled (security)
   - ✅ Public access blocked (security)
   - ✅ Lifecycle prevention (can't accidentally delete)

2. **DynamoDB Table** (`terraform-state-lock`):
   - ✅ State locking (prevents concurrent modifications)
   - ✅ Pay-per-request billing (cost effective)
   - ✅ Lifecycle prevention (can't accidentally delete)

## 🚀 Usage:

### 1. Create the backend infrastructure:
```bash
cd terraform/tf-backend
terraform init
terraform plan
terraform apply
```

### 2. Copy the backend configuration:
After `terraform apply`, copy the backend configuration from the output and add it to your environment configurations.

### 3. Update your environment configs:
Add the backend block to `tf-dev/versions.tf`, `tf-qa/versions.tf`, and `tf-prod/versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "setadvanced-terraform-state"
    key            = "environments/dev/terraform.tfstate"  # Change for each env
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 4. Migrate existing state (if any):
```bash
cd terraform/tf-dev
terraform init  # Will prompt to migrate existing state
```

## 🔒 Security Features:

- **Encryption at rest**: S3 server-side encryption
- **Access control**: Public access completely blocked
- **State locking**: Prevents concurrent modifications
- **Versioning**: Keep history of state changes
- **Lifecycle protection**: Can't accidentally destroy backend

## 💰 Cost:

- **S3**: ~$0.02/month for state files
- **DynamoDB**: ~$0.00 (pay-per-request, minimal usage)
- **Total**: Less than $1/month

## 🛡️ Important Notes:

1. **This configuration uses LOCAL state** because it's creating the backend for other configs
2. **Keep this simple** - don't put complex infrastructure here
3. **Backup the backend state file** (terraform.tfstate in this folder)
4. **One backend per AWS account/region** - can be shared across projects

## 🔄 Bootstrap Process:

```
1. tf-backend/ (local state) → Creates S3 + DynamoDB
2. tf-dev/ (remote state) → Uses S3 + DynamoDB backend
3. tf-qa/ (remote state) → Uses S3 + DynamoDB backend  
4. tf-prod/ (remote state) → Uses S3 + DynamoDB backend
```

This is the **chicken-and-egg solution** - use local state to create remote state infrastructure! 🥚🐔