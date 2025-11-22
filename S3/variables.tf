// S3バケット名の変数定義
// バケット名はAWS全体でグローバルに一意である必要がある
variable "bucket_name" {
  // コンソール上での説明表示用
  description = "S3バケットの名前"
  type        = string // 文字列型
  // デフォルト値なし = 必須パラメータ
}

// 環境名の変数定義
// リソースの用途や環境を識別するために使用
variable "environment" {
  description = "環境名 (dev, staging, prod など)"
  type        = string // 文字列型
  default     = "dev"  // デフォルト値は "dev" (開発環境)
}

// S3にアップロードするローカルファイルのパス
variable "source_path" {
  description = "アップロードするローカルファイルのパス"
  type        = string
  default     = "upload_file/example.txt"
}

// S3バケット内でのオブジェクトキー (ファイル名)
variable "object_key" {
  description = "S3バケット内でのオブジェクトキー (ファイルパス)"
  type        = string
  default     = "example.txt"
}
