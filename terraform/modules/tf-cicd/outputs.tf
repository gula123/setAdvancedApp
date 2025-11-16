output "codepipeline_name" {
  value       = aws_codepipeline.cicd_pipeline.name
  description = "Name of the CodePipeline"
}

output "codepipeline_arn" {
  value       = aws_codepipeline.cicd_pipeline.arn
  description = "ARN of the CodePipeline"
}

output "ci_codebuild_project_name" {
  value       = aws_codebuild_project.ci_build.name
  description = "Name of the CI CodeBuild project"
}

output "deploy_codebuild_project_name" {
  value       = aws_codebuild_project.deploy_build.name
  description = "Name of the Deploy CodeBuild project"
}

output "artifacts_bucket_name" {
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
  description = "Name of the S3 bucket for CodePipeline artifacts"
}

output "codebuild_ci_role_arn" {
  value       = aws_iam_role.codebuild_ci_role.arn
  description = "ARN of the CodeBuild CI role"
}

output "codebuild_deploy_role_arn" {
  value       = aws_iam_role.codebuild_deploy_role.arn
  description = "ARN of the CodeBuild Deploy role"
}

output "codepipeline_role_arn" {
  value       = aws_iam_role.codepipeline_role.arn
  description = "ARN of the CodePipeline role"
}

output "codedeploy_application_name" {
  value       = aws_codedeploy_application.app.name
  description = "Name of the CodeDeploy application"
}

output "codedeploy_deployment_group_name" {
  value       = aws_codedeploy_deployment_group.app_deployment_group.deployment_group_name
  description = "Name of the CodeDeploy deployment group"
}

output "codedeploy_role_arn" {
  value       = aws_iam_role.codedeploy_role.arn
  description = "ARN of the CodeDeploy role"
}