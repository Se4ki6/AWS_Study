# ============================================================
# IAMモジュール 出力値
# ============================================================

# OpenSearch_Serverless・Bedrockモジュールでポリシー設定・KB作成に使用
output "role_arn" {
  value = aws_iam_role.bedrock_kb_role.arn
}

# OpenSearch_Serverlessモジュールでインラインポリシーのアタッチに使用
output "role_id" {
  value = aws_iam_role.bedrock_kb_role.id
}

# ▼▼▼ Bedrockモジュール（Lambda）でLambda実行ロールに使用 ▼▼▼
output "lambda_trigger_role_arn" {
  value = aws_iam_role.lambda_trigger_role.arn
}
