# ============================================================
# OpenSearch Serverlessモジュール 変数定義
# ============================================================

# IAMポリシーのアタッチ先（Principalとして設定）
variable "role_arn" {
  description = "Bedrock Knowledge Base IAM role ARN"
  type        = string
}

# IAMインラインポリシーのアタッチ先（role名指定に使用）
variable "role_id" {
  description = "Bedrock Knowledge Base IAM role ID"
  type        = string
}

# S3バケットへのアクセス権限設定に使用
variable "bucket_arn" {
  description = "S3 bucket ARN for knowledge base data"
  type        = string
}

# OpenSearch Dashboardsにアクセスするための操作者IAMユーザーARN
# SSOユーザーはダッシュボードにアクセスできないため、
# IAMユーザーでのダッシュボードアクセスが必要な場合に指定する
variable "operator_iam_user_arn" {
  description = "IAM user ARN for OpenSearch Dashboards access (e.g. arn:aws:iam::ACCOUNT:user/USERNAME)"
  type        = string
  default     = ""
}
