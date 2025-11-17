# CI Pipeline for Pull Request Validation
module "ci_pipeline" {
  source = "../modules/tf-ci"

  # Environment Configuration
  environment = "ci"
  project_name = "setadvanced"

  # GitHub Configuration
  github_owner = "gula123"
  github_repo  = "setAdvancedApp"
  github_token = var.github_token

  # AWS Configuration
  region     = "eu-north-1"
  account_id = var.account_id
}