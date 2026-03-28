# ============================================================
# S3モジュール 出力値
# ============================================================

# IAM・OpenSearch_Serverless・Bedrockモジュールでアクセス権限設定に使用
output "bucket_arn" {
  value = aws_s3_bucket.obsidian_data.arn
}

# IAMモジュールでロール名のユニーク化に使用
output "random_id_hex" {
  value = random_id.id.hex
}

# ▼▼▼ Bedrockモジュール（EventBridgeルール）でS3バケットのフィルタリングに使用 ▼▼▼
output "bucket_name" {
  value = aws_s3_bucket.obsidian_data.bucket
}
