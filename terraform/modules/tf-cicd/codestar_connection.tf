# CodeStar Connection for GitHub v2 (required for trigger filters)
resource "aws_codestarconnections_connection" "github" {
  count         = var.use_github_v2 ? 1 : 0
  name          = "${var.project_name}-github-connection-${var.environment}"
  provider_type = "GitHub"
}

# Output for manual connection activation
output "github_connection_arn" {
  value       = var.use_github_v2 ? aws_codestarconnections_connection.github[0].arn : null
  description = "GitHub connection ARN (needs manual activation in console)"
}

output "github_connection_status" {
  value       = var.use_github_v2 ? aws_codestarconnections_connection.github[0].connection_status : null
  description = "GitHub connection status"
}
