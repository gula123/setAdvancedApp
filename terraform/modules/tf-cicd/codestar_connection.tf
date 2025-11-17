# CodeStar Connection for GitHub v2 (required for trigger filters)
resource "aws_codestarconnections_connection" "github" {
  count         = var.use_github_v2 && var.github_connection_arn == "" ? 1 : 0
  name          = "${var.project_name}-github-connection-${var.environment}"
  provider_type = "GitHub"
}
