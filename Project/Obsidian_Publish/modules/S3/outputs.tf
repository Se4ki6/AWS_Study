output "bucket_name" {
  description = "S3バケット名（GitHub Secretsに設定するS3_BUCKET）"
  value       = aws_s3_bucket.deploy_artifact.id
}
