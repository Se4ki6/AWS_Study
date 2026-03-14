output "amplify_app_id" {
  description = "GitHub Secretsに設定するAMPLIFY_APP_ID"
  value       = module.amplify.app_id
}

output "amplify_default_domain" {
  description = "サイトのURL"
  value       = module.amplify.default_domain
}

output "s3_bucket_name" {
  description = "GitHub Secretsに設定するS3_BUCKET"
  value       = module.s3.bucket_name
}
