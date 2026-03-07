variable "api_name" {
  type        = string
  description = "API Gatewayの名前"
}

variable "environment" {
  type        = string
  description = "環境名 (dev, prodなど)"
}

variable "lambda_function_arn" {
  type        = string
  description = "統合するLambda関数のARN"
}

variable "lambda_function_name" {
  type        = string
  description = "権限付与に使うLambda関数の名前"
}
