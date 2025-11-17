# CI CodeBuild Project
resource "aws_codebuild_project" "ci_build" {
  name          = "${var.project_name}-ci-${var.environment}"
  description   = "CI build project for ${var.project_name} ${var.environment}"
  service_role  = aws_iam_role.codebuild_ci_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.project_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-ci.yml"
  }

  tags = {
    Name        = "${var.project_name}-ci-${var.environment}"
    Environment = var.environment
  }
}

# Deployment CodeBuild Project
resource "aws_codebuild_project" "deploy_build" {
  name          = "${var.project_name}-deploy-${var.environment}"
  description   = "Deployment build project for ${var.project_name} ${var.environment}"
  service_role  = aws_iam_role.codebuild_deploy_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_uri
    }

    environment_variable {
      name  = "ECS_CONTAINER_NAME"
      value = var.container_name
    }

    environment_variable {
      name  = "S3_BUCKET_NAME"
      value = var.s3_bucket_name
    }

    environment_variable {
      name  = "LAMBDA_NAME"
      value = var.lambda_function_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }

  tags = {
    Name        = "${var.project_name}-deploy-${var.environment}"
    Environment = var.environment
  }
}

# Integration Tests CodeBuild Project (all environments)
resource "aws_codebuild_project" "integration_tests" {
  name         = "${var.project_name}-integration-tests-${var.environment}"
  description  = "Integration tests for ${var.environment} environment"
  service_role = aws_iam_role.codebuild_deploy_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = var.ecs_cluster_name
    }

    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = var.ecs_service_name
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = var.lambda_function_name
    }

    environment_variable {
      name  = "ALB_DNS_NAME"
      value = var.alb_dns_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-integration-tests.yml"
  }

  tags = {
    Name        = "${var.project_name}-integration-tests-${var.environment}"
    Environment = var.environment
    Purpose     = "Integration Testing"
  }
}

# PR Validation CodeBuild Project - Terraform Static Analysis
resource "aws_codebuild_project" "pr_validation" {
  count        = var.enable_pr_validation ? 1 : 0
  name         = "${var.project_name}-pr-validation-${var.environment}"
  description  = "PR validation with Terraform static analysis for ${var.environment}"
  service_role = aws_iam_role.codebuild_pr_validation_role[0].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = var.github_token
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "GITHUB_REPO"
      value = "${var.github_owner}/${var.github_repo}"
    }

    environment_variable {
      name  = "TARGET_BRANCH"
      value = var.github_branch
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github_owner}/${var.github_repo}.git"
    git_clone_depth = 1
    buildspec       = "buildspec-terraform-validate.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = var.github_branch

  tags = {
    Name        = "${var.project_name}-pr-validation-${var.environment}"
    Environment = var.environment
    Purpose     = "PR Validation"
  }
}

# Infrastructure Tests CodeBuild Project
resource "aws_codebuild_project" "infrastructure_tests" {
  name         = "${var.project_name}-infrastructure-tests-${var.environment}"
  description  = "Infrastructure validation tests for ${var.environment}"
  service_role = aws_iam_role.codebuild_deploy_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = false

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-infrastructure-tests.yml"
  }

  tags = {
    Name        = "${var.project_name}-infrastructure-tests-${var.environment}"
    Environment = var.environment
    Purpose     = "Infrastructure Testing"
  }
}