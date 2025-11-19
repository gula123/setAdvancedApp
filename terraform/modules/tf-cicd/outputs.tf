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
  value       = var.target_group_green_name != "" ? aws_codedeploy_app.app[0].name : null
  description = "Name of the CodeDeploy application"
}

output "codedeploy_deployment_group_name" {
  value       = var.target_group_green_name != "" ? aws_codedeploy_deployment_group.app_deployment_group[0].deployment_group_name : null
  description = "Name of the CodeDeploy deployment group"
}

output "codedeploy_role_arn" {
  value       = var.target_group_green_name != "" ? aws_iam_role.codedeploy_role[0].arn : null
  description = "ARN of the CodeDeploy role"
}

output "github_connection_arn" {
  value       = var.use_github_v2 ? (var.github_connection_arn != "" ? var.github_connection_arn : aws_codestarconnections_connection.github[0].arn) : null
  description = "GitHub connection ARN (needs manual activation in console)"
}

output "github_connection_status" {
  value       = var.use_github_v2 ? (var.github_connection_arn != "" ? "EXTERNAL" : aws_codestarconnections_connection.github[0].connection_status) : null
  description = "GitHub connection status"
}

output "pr_validation_project_name" {
  value       = var.enable_pr_validation ? aws_codebuild_project.pr_validation[0].name : null
  description = "Name of the PR validation CodeBuild project"
}

output "pr_unit_tests_project_name" {
  value       = var.enable_pr_validation ? aws_codebuild_project.pr_unit_tests[0].name : null
  description = "Name of the PR unit tests CodeBuild project"
}