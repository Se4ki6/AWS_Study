# ============================================================
# Bedrockモジュール 変数定義
# ============================================================

# ナレッジベース作成時のIAMロール
variable "role_arn" {
  description = "Bedrock Knowledge Base IAM role ARN"
  type        = string
}

# ベクトルDBコレクションのARN（ストレージ設定で使用）
variable "collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  type        = string
}

# S3データソースのARN（データソース設定で使用）
variable "bucket_arn" {
  description = "S3 bucket ARN for knowledge base data"
  type        = string
}

# 手動トリガーLambdaの実行ロール
variable "lambda_trigger_role_arn" {
  description = "IAM role ARN for the ingestion trigger Lambda"
  type        = string
}
