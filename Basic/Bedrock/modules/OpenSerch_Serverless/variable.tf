variable "role_arn" {
  description = "Bedrock Knowledge Base IAM role ARN"
  type        = string
}

variable "role_id" {
  description = "Bedrock Knowledge Base IAM role ID"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN for knowledge base data"
  type        = string
}
