variable "table_name" {
  type        = string
  description = "作成するDynamoDBのテーブル名"
}

variable "environment" {
  type        = string
  description = "デプロイする環境名 (例: dev, prod)"
}
