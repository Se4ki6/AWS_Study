variable "role_arn" {
  description = "Bedrock Knowledge Base IAM role ARN"
  type        = string
}

variable "collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN for knowledge base data"
  type        = string
}
