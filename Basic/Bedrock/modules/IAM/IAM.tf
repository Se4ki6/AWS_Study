# ============================================================
# IAMモジュール
# ============================================================

# ------------------------------------------------------------
# BedrockナレッジベースのIAMロール
# BedrockサービスがS3・OpenSearch Serverlessにアクセスするために使用
# ポリシー（S3/AOSS/Bedrock権限）はOpenSearch_Serverlessモジュールでアタッチ
# （AOSSのARNが必要なため、循環依存を避けるためあちら側で定義）
# ------------------------------------------------------------
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

# ============================================================
# ▼▼▼ Lambda実行用IAMロール（差分取り込み自動トリガー用） ▼▼▼
# EventBridgeがこのロールでLambdaを起動し、
# LambdaがBedrockのStartIngestionJobを呼び出して差分取り込みを実行する
# ============================================================
resource "aws_iam_role" "lambda_trigger_role" {
  name = "BedrockIngestionTriggerRole-${var.random_id_hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Lambda基本実行権限（CloudWatch Logsへの書き込み）
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_trigger_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# BedrockのStartIngestionJob呼び出し権限
resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "LambdaBedrockIngestionPolicy"
  role = aws_iam_role.lambda_trigger_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:StartIngestionJob"]
      Resource = "*"
    }]
  })
}
