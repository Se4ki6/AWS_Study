output "app_id" {
  description = "AmplifyアプリID（GitHub Secretsに設定するAMPLIFY_APP_ID）"
  value       = aws_amplify_app.this.id
}

output "default_domain" {
  description = "Amplifyが発行するデフォルトドメイン"
  value       = aws_amplify_app.this.default_domain
}
