# ④ Pythonのコードを自動でZIPファイルにまとめる
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src" # srcフォルダの中身をZIPにする
  output_path = "${path.module}/upload/lambda.zip"
}

# ⑤ Lambda関数本体の設定
resource "aws_lambda_function" "vote_function" {
  function_name = "${var.function_name}-${var.environment}"
  role          = aws_iam_role.lambda_exec_role.arn # ← iam.tfで作ったロールを参照！
  handler       = "app.lambda_handler"
  runtime       = "python3.12"

  # さっき作ったZIPファイルをデプロイする
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Lambdaのプログラム内で使える環境変数をセット！
  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }
}
