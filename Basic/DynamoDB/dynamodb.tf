resource "aws_dynamodb_table" "todo_table" {
  name         = var.table_name      # テーブル名
  billing_mode = "PAY_PER_REQUEST" # オンデマンドモード（サーバーレス向け！）
  hash_key     = var.hash_key       # パーティションキー（必須）
#   range_key    = var.range_key      # ソートキー（オプション・必要なら書く）

  # キーに指定した項目の「型」を定義するよ
  # S = String(文字列), N = Number(数値), B = Binary(バイナリ)
  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.attribute_name
    type = "S"
  }

  # リソースの管理用にタグをつけておくと後で便利！
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}