# CodePipeline for CI/CD
resource "aws_codepipeline" "cicd_pipeline" {
  name     = "${var.project_name}-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "CI_Build"

    action {
      name             = "CI_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["ci_build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ci_build.name
      }
    }
  }

  stage {
    name = "Deploy_Build"

    action {
      name             = "Deploy_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deploy_build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["deploy_build_output"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_application.app.name
        DeploymentGroupName           = aws_codedeploy_deployment_group.app_deployment_group.deployment_group_name
        TaskDefinitionTemplateArtifact = "deploy_build_output"
        AppSpecTemplateArtifact       = "deploy_build_output"
        TaskDefinitionTemplatePath    = "taskdef.json"
        AppSpecTemplatePath           = "appspec.yaml"
      }
    }
  }

  # Add manual approval for non-dev environments
  dynamic "stage" {
    for_each = var.environment != "dev" ? [1] : []
    content {
      name = "Manual_Approval"

      action {
        name     = "Manual_Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          CustomData = "Please review the deployment to ${var.environment} environment before proceeding"
        }
      }
    }
  }

  # Add integration tests stage for QA/PROD
  dynamic "stage" {
    for_each = var.environment != "dev" ? [1] : []
    content {
      name = "Integration_Tests"

      action {
        name             = "Integration_Tests"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["deploy_build_output"]
        output_artifacts = ["test_output"]
        version          = "1"

        configuration = {
          ProjectName = aws_codebuild_project.integration_tests[0].name
        }
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Event Rule for triggering pipeline on GitHub webhook
resource "aws_cloudwatch_event_rule" "github_push" {
  name        = "${var.project_name}-github-push-${var.environment}"
  description = "Trigger pipeline on GitHub push to ${var.github_branch}"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.cicd_pipeline.name]
    }
  })

  tags = {
    Name        = "${var.project_name}-github-push-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "codepipeline" {
  rule      = aws_cloudwatch_event_rule.github_push.name
  target_id = "TriggerCodePipeline"
  arn       = aws_codepipeline.cicd_pipeline.arn
  role_arn  = aws_iam_role.codepipeline_event_role.arn
}

# IAM Role for CloudWatch Events
resource "aws_iam_role" "codepipeline_event_role" {
  name = "codepipeline-event-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for CloudWatch Events
resource "aws_iam_role_policy" "codepipeline_event_policy" {
  name = "codepipeline-event-policy-${var.environment}"
  role = aws_iam_role.codepipeline_event_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = aws_codepipeline.cicd_pipeline.arn
      }
    ]
  })
}