variable "app_name" {
  description = "Amplifyアプリケーション名"
  type        = string
}

variable "github_repository_url" {
  description = "Amplifyで接続するGitHubリポジトリURL"
  type        = string
}

variable "github_token" {
  description = "GitHubリポジトリ接続用のPersonal Access Token"
  type        = string
  sensitive   = true
}
