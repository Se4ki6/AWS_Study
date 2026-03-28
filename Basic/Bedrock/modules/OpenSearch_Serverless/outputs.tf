# ============================================================
# OpenSearch Serverlessモジュール 出力値
# ============================================================

# Bedrockモジュールでナレッジベースのストレージ設定先として使用
output "collection_arn" {
  value = aws_opensearchserverless_collection.vector_db.arn
}

# （参照用）BedrockKnowledgeBasePolicyのID
output "kb_policy_id" {
  value = aws_iam_role_policy.bedrock_kb_policy.id
}

# （参照用）データアクセスポリシー名
output "access_policy_name" {
  value = aws_opensearchserverless_access_policy.data_policy.name
}
