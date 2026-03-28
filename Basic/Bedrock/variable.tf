# ============================================================
# ルートモジュール 変数定義
# ============================================================

variable "aws_profile" {
  description = "~/.aws/credentials に設定されているAWSプロファイル名"
  type        = string
  default     = "default"
}

variable "operator_iam_user_arn" {
  description = "OpenSearch DashboardsにアクセスするIAMユーザーARN（SSOではダッシュボード不可のため別途指定）"
  type        = string
  default     = ""
}
