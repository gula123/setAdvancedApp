# GitHub Webhook for PR Events
# =============================
# This configures GitHub webhook integration to trigger PR validation
# when pull requests are created or updated targeting the configured branch

resource "aws_codebuild_webhook" "pr_validation" {
  count        = var.enable_pr_validation ? 1 : 0
  project_name = aws_codebuild_project.pr_validation[0].name

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
