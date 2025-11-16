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

  # Deploy stage - use CodeDeployToECS for Blue-Green, ECS for standard deployment
  dynamic "stage" {
    for_each = var.target_group_green_name != "" ? [1] : []
    content {
      name = "Deploy_BlueGreen"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CodeDeployToECS"
        input_artifacts = ["deploy_build_output"]
        version         = "1"

        configuration = {
          ApplicationName                = aws_codedeploy_app.app[0].name
          DeploymentGroupName            = aws_codedeploy_deployment_group.app_deployment_group[0].deployment_group_name
          TaskDefinitionTemplateArtifact = "deploy_build_output"
          AppSpecTemplateArtifact        = "deploy_build_output"
          TaskDefinitionTemplatePath     = "taskdef.json"
          AppSpecTemplatePath            = "appspec.yaml"
        }
      }
    }
  }

  # Standard ECS deployment (no Blue-Green)
  dynamic "stage" {
    for_each = var.target_group_green_name == "" ? [1] : []
    content {
      name = "Deploy_ECS"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ECS"
        input_artifacts = ["deploy_build_output"]
        version         = "1"

        configuration = {
          ClusterName = var.ecs_cluster_name
          ServiceName = var.ecs_service_name
          FileName    = "imagedefinitions.json"
        }
      }
    }
  }

  # Infrastructure tests - verify deployment health
  stage {
    name = "Infrastructure_Tests"

    action {
      name             = "Infrastructure_Tests"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["deploy_build_output"]
      output_artifacts = ["infrastructure_test_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.infrastructure_tests.name
      }
    }
  }

  # API integration tests stage for all environments
  stage {
    name = "API_Integration_Tests"

    action {
      name             = "API_Tests"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["deploy_build_output"]
      output_artifacts = ["api_test_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.integration_tests.name
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