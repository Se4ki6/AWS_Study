terraform {
  // terraformのバージョンを指定
  required_version = ">= 1.9.0"

  // awsプロバイダーのバージョンを指定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

// awsプロバイダーの設定
provider "aws" {
  // regionを指定
  region = "ap-southeast-2"
}

// S3バケットの作成
// aws_s3_bucket: S3バケットを作成するリソース（`resource "<リソースタイプ>" "<リソース名>"`）
resource "aws_s3_bucket" "example" {
  // バケット名を指定 (グローバルで一意である必要がある)
  bucket = var.bucket_name // variables.tf で定義されている変数から値を取得

  // バケットに付与するタグ
  // タグを使用することでリソースの管理や検索が容易になる
  tags = {
    Name        = var.bucket_name // バケットの表示名
    Environment = var.environment // 環境の種類 (dev, staging, prodなど)
    ManagedBy   = "Terraform"     // このリソースがTerraformで管理されていることを示す
  }
}

// S3バケットのバージョニング設定（変更履歴を保持するための設定）
// バージョニングを有効にすることで、オブジェクトの複数バージョンを保持できる
// 誤削除や上書きからデータを保護するために推奨される設定
resource "aws_s3_bucket_versioning" "example" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    // バージョニングを有効化 ("Enabled" or "Suspended")
    status = "Enabled"
  }
}

// S3バケットの暗号化設定
// サーバーサイド暗号化により、保存されるデータを自動的に暗号化する
// セキュリティ要件を満たすために重要な設定
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  rule {
    // デフォルトの暗号化設定を適用
    apply_server_side_encryption_by_default {
      // 暗号化アルゴリズムを指定
      // AES256: AWS S3マネージドキーによる暗号化
      // aws:kms: AWS KMSマネージドキーによる暗号化も選択可能
      sse_algorithm = "AES256"
    }
  }
}

// S3バケットのパブリックアクセスブロック設定
// バケットへの意図しない公開アクセスを防ぐためのセキュリティ設定
// セキュリティベストプラクティスとして推奨される
resource "aws_s3_bucket_public_access_block" "main" {
  // 対象のS3バケットIDを指定
  bucket = aws_s3_bucket.example.id

  // 以下4つの設定を有効化することにより、バケットが完全にプライベートであることを保証
  // 新しいパブリックACL (Access Control List) の適用をブロック
  block_public_acls = true
  // 新しいパブリックバケットポリシーの適用をブロック
  block_public_policy = true
  // 既存のパブリックACLを無視する
  ignore_public_acls = true
  // パブリックアクセスが許可されているバケットとオブジェクトへのアクセスを制限
  restrict_public_buckets = true
}

// ローカルのファイルをAWS S3バケットにアップロードする設定 (旧バージョン - 非推奨)
// resource "aws_s3_bucket_object" "upload_file" {
//   // アップロード先のS3バケット名を指定
//   bucket = aws_s3_bucket.example.id
//
//   // S3内でのオブジェクトのキー (パス) を指定
//   key = var.object_key // variables.tf で定義されている変数から値を取得
//
//   // ローカルのファイルパスを指定
//   source = var.source_path // variables.tf で定義されている変数から値を取得
//
//   // filemd5ハッシュを計算して整合性を検証
//   etag = filemd5(var.source_path)
//
//   // コンテンツタイプを指定 (MIMEタイプ)
//   content_type = "text/plain"
//   # アクセス制御をprivateに設定
//   acl = "private"
// }

// ローカルのファイルをAWS S3バケットにアップロードする設定 (推奨版)
// aws_s3_object は aws_s3_bucket_object の後継リソース
resource "aws_s3_object" "upload_file" {
  // アップロード先のS3バケット名を指定
  bucket = aws_s3_bucket.example.id

  // S3内でのオブジェクトのキー (パス) を指定
  key = var.object_key // variables.tf で定義されている変数から値を取得

  // ローカルのファイルパスを指定
  source = var.source_path // variables.tf で定義されている変数から値を取得

  // filemd5ハッシュを計算して整合性を検証
  etag = filemd5(var.source_path)

  // コンテンツタイプを指定 (MIMEタイプ)
  content_type = "text/plain"

  // 注意: aclパラメータは削除
  // バケットのパブリックアクセスブロック設定により、デフォルトでprivateになります
}
