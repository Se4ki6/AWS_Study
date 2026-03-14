resource "aws_iam_role" "bedrock_kb_role" {
  name = "BedrockKnowledgeBaseRole-${var.random_id_hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
    }]
  })
}
