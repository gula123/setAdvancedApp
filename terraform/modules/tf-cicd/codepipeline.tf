# CodePipeline for CI/CD
resource "aws_codepipeline" "cicd_pipeline" {
  name     = "${var.project_name}-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  # Trigger configuration for GitHub v2 with branch patterns
  dynamic "trigger" {
    for_each = var.use_github_v2 && length(var.github_trigger_branch_patterns) > 0 ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "Source"
        push {
          branches {
            includes = var.github_trigger_branch_patterns
          }
        }
      }
    }
  }

  stage {
    name = "Source"

    # GitHub v1 source (OAuth)
    dynamic "action" {
      for_each = var.use_github_v2 ? [] : [1]
      content {
        name             = "Source"
        category         = "Source"
        owner            = "ThirdParty"
        provider         = "GitHub"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          Owner                = var.github_owner
          Repo                 = var.github_repo
          Branch               = var.github_branch
          OAuthToken           = var.github_token
          PollForSourceChanges = "true"
        }
      }
    }

    # GitHub v2 source (CodeStar Connections)
    dynamic "action" {
      for_each = var.use_github_v2 ? [1] : []
      content {
        name             = "Source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          ConnectionArn        = var.github_connection_arn != "" ? var.github_connection_arn : aws_codestarconnections_connection.github[0].arn
          FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
          BranchName           = var.github_branch
          OutputArtifactFormat = "CODE_ZIP"
        }
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
      input_artifacts  = ["ci_build_output"]
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
      input_artifacts  = ["source_output"]
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
      input_artifacts  = ["source_output"]
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

# Note: GitHub OAuth v1 source action uses polling (checks every ~1 minute)
# No EventBridge rules or webhooks needed for GitHub v1
# For webhook-based triggering, migrate to GitHub v2 (CodeStar Connections)