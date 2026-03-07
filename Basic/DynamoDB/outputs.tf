output "dynamodb_table_name" {
  value       = aws_dynamodb_table.todo_table.name
  description = "DynamoDBテーブル名"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.todo_table.arn
  description = "DynamoDBテーブルのARN"
}
