resource "aws_s3_bucket" "deploy_artifact" {
  bucket = var.bucket_name
}

# GitHub Actionsからのアップロードのみでよいのでパブリックアクセスはブロック
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.deploy_artifact.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 古いデプロイ成果物を自動削除（7日保持）
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.deploy_artifact.id

  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }
  }
}
