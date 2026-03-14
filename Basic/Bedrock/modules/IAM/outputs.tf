output "role_arn" {
  value = aws_iam_role.bedrock_kb_role.arn
}

output "role_id" {
  value = aws_iam_role.bedrock_kb_role.id
}
