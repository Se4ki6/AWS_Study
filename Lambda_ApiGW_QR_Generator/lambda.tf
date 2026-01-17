# --- IAM Role ---
resource "aws_iam_role" "lambda_exec" {
  name = "qr_generator_lambda_role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda ZIPファイルの自動ビルド ---
resource "null_resource" "lambda_build" {
  triggers = {
    handler_hash      = filemd5("${path.module}/lambda_code/handler.py")
    requirements_hash = filemd5("${path.module}/lambda_code/requirements.txt")
  }

  provisioner "local-exec" {
    command     = var.is_windows ? "powershell -ExecutionPolicy Bypass -File ${path.module}/script/build.ps1" : "bash ${path.module}/script/build.sh"
    working_dir = path.module
  }
}

# --- Lambda Function ---
resource "aws_lambda_function" "qr_generator" {
  depends_on = [null_resource.lambda_build]

  filename         = "lambda_function_payload.zip"
  function_name    = "qr-generator-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}
