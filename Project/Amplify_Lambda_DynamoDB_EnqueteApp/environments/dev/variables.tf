# profile
variable "aws_profile" {
  type = string
}

# プロジェクト全体
variable "env_name" {
  type = string
}

# DynamoDB用
variable "db_table_name" {
  type = string
}

# Lambda用
variable "lambda_function_name" {
  type = string
}

# API Gateway用
variable "api_name" {
  type = string
}

# Amplify用
variable "app_name" {
  type = string
}

variable "github_repository_url" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true # ログに出さないための設定
}
