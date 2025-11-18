# GitHub Source Credential for CodeBuild
# =========================================
# This provides GitHub OAuth token for CodeBuild to access private repositories
# and create webhooks

resource "aws_codebuild_source_credential" "github" {
  count       = var.enable_pr_validation ? 1 : 0
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

# GitHub Webhook for PR Events
# =============================
# This configures GitHub webhook integration to trigger PR validation
# when pull requests are created or updated targeting the configured branch

resource "aws_codebuild_webhook" "pr_validation" {
  count        = var.enable_pr_validation ? 1 : 0
  project_name = aws_codebuild_project.pr_validation[0].name

  # Ensure source credential is created first
  depends_on = [aws_codebuild_source_credential.github]

  # Disable comment approval requirement - trigger automatically on PR events
  build_type = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED,PULL_REQUEST_UPDATED,PULL_REQUEST_REOPENED"
    }

    filter {
      type    = "BASE_REF"
      pattern = "^refs/heads/${var.github_branch}$"
    }
  }
}
