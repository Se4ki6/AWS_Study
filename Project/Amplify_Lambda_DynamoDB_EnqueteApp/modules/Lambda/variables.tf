variable "function_name" {
  type        = string
  description = "作成するLambda関数のベース名"
}

variable "environment" {
  type        = string
  description = "環境名 (dev, prodなど)"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Lambda関数内で使うDynamoDBテーブルの名前"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "Lambda関数に権限付与するDynamoDBテーブルのARN"
}
