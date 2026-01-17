output "environment" {
  description = "Current Environment"
  value       = var.environment
}

output "api_endpoint" {
  description = "QR Code Generation URL"
  value       = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/generate?url=https://example.com"
}

output "api_endpoint_full" {
  description = "Full API Endpoint URL (${var.environment})"
  value       = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.lambda_api.id
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = aws_lambda_function.qr_generator.function_name
}

# Dev環境のみのデバッグ情報
output "debug_info" {
  description = "Debug Information (dev only)"
  value = var.environment == "dev" ? {
    lambda_arn        = aws_lambda_function.qr_generator.arn
    lambda_version    = aws_lambda_function.qr_generator.version
    api_execution_arn = aws_apigatewayv2_api.lambda_api.execution_arn
  } : null
}

# 環境別のメッセージ
output "deployment_message" {
  description = "Deployment Status Message"
  value       = var.environment == "prod" ? "✅ Production deployment complete. Use with caution." : "🚀 Development environment ready for testing."
}
