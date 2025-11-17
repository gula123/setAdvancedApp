variable "github_token" {
  type        = string
  description = "GitHub personal access token for CodePipeline to access repository"
  sensitive   = true
}