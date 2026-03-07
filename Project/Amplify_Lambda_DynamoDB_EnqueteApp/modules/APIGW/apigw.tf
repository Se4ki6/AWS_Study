# ① HTTP APIの作成
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.api_name}-${var.environment}"
  protocol_type = "HTTP"

  # CORSの設定（これがないとフロントエンドから通信エラーになっちゃう！）
  cors_configuration {
    allow_origins = ["*"] # 本番環境ではフロントエンドのドメインに絞るのが安全だよ
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

# ② デプロイするステージ（環境）設定
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true # 変更があったら自動でデプロイしてくれる便利機能
}

# ③ Lambdaとの統合（つなぎ込み）設定
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_function_arn # 受け取ったLambdaのARNを指定
  payload_format_version = "2.0"
}

# ④ ルーティング（パス）の設定
# "ANY /{proxy+}" にすることで、どんなURL（/polls/xxx など）で来てもLambdaに流すよ！
resource "aws_apigatewayv2_route" "any_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# ⑤ API GatewayがLambdaを呼び出すための「許可証（リソースベースポリシー）」
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
