variable "github_token" {
  type        = string
  description = "GitHub personal access token for repository access"
  sensitive   = true
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}