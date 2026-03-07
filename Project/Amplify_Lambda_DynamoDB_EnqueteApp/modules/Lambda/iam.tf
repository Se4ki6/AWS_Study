# ① Lambdaが被る「役職（IAMロール）」を作る
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.function_name}-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# ② DynamoDBへのアクセスと、エラー時のログ出力の「許可証（IAMポリシー）」を作る
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.function_name}-policy-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem", # アトミックカウンタ用
          "dynamodb:GetItem",    # データ取得用
          "dynamodb:Scan",       # 全件取得用
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn # 特定のテーブルだけ許可！
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ③ 役職（ロール）に許可証（ポリシー）を持たせる
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
