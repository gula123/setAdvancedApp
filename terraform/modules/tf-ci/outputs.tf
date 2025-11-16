output "ci_pipeline_name" {
  description = "CI Pipeline name"
  value       = aws_codepipeline.ci_pipeline.name
}

output "ci_pipeline_arn" {
  description = "CI Pipeline ARN"
  value       = aws_codepipeline.ci_pipeline.arn
}

output "ci_codebuild_project_name" {
  description = "CI CodeBuild project name"
  value       = aws_codebuild_project.ci_build.name
}

output "ci_s3_artifacts_bucket" {
  description = "CI S3 artifacts bucket name"
  value       = aws_s3_bucket.ci_artifacts.bucket
}