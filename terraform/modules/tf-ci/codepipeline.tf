# CI-only Pipeline for Pull Request Validation
resource "aws_codepipeline" "ci_pipeline" {
  name     = "${var.project_name}-ci-pipeline"
  role_arn = aws_iam_role.ci_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.ci_artifacts.bucket
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
        Branch     = "development"  # Monitor development branch for PR merges
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "CI_Validation"

    action {
      name             = "CI_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["ci_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ci_build.name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-ci-pipeline"
    Environment = var.environment
    Purpose     = "CI Validation"
  }
}

# CloudWatch Event Rule for GitHub webhooks on development branch
resource "aws_cloudwatch_event_rule" "github_ci_webhook" {
  name        = "${var.project_name}-github-ci-webhook"
  description = "Trigger CI pipeline on GitHub push to development branch"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.ci_pipeline.name]
    }
  })

  tags = {
    Name        = "${var.project_name}-github-ci-webhook"
    Environment = var.environment
  }
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "ci_pipeline_trigger" {
  rule      = aws_cloudwatch_event_rule.github_ci_webhook.name
  target_id = "TriggerCIPipeline"
  arn       = aws_codepipeline.ci_pipeline.arn
  role_arn  = aws_iam_role.ci_codepipeline_role.arn
}