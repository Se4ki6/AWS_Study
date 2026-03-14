output "collection_arn" {
  value = aws_opensearchserverless_collection.vector_db.arn
}

output "kb_policy_id" {
  value = aws_iam_role_policy.bedrock_kb_policy.id
}

output "access_policy_name" {
  value = aws_opensearchserverless_access_policy.data_policy.name
}
