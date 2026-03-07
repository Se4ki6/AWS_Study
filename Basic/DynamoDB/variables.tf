variable "aws_profile" {
  description = "AWS CLIのプロファイル名"
  type        = string
}

variable "table_name" {
  description = "DynamoDBテーブルの名前"
  type        = string

}

variable "hash_key" {
  description = "DynamoDBテーブルのパーティションキーの名前"
  type        = string
}

# variable "range_key" {
#   description = "DynamoDBテーブルのソートキーの名前（必要な場合）"
#   type        = string
# }

variable "environment" {
  description = "環境名（例: dev, staging, prod）"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "attribute_name" {
  description = "DynamoDBテーブルの追加属性の名前"
  type        = string
  default     = "Attribute1" # デフォルトの属性名
}
