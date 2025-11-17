# CI CodeBuild Project for Pull Request Validation
resource "aws_codebuild_project" "ci_build" {
  name         = "${var.project_name}-ci-${var.environment}"
  description  = "CI pipeline for pull request validation"
  service_role = aws_iam_role.ci_codebuild_role.arn

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
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "${var.project_name}/app"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-ci.yml"
  }

  tags = {
    Name        = "${var.project_name}-ci-${var.environment}"
    Environment = var.environment
    Purpose     = "CI Pipeline"
  }
}