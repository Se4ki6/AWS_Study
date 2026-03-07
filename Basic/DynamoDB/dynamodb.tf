resource "aws_dynamodb_table" "todo_table" {
  name         = "todo-table"      # テーブル名
  billing_mode = "PAY_PER_REQUEST" # オンデマンドモード（サーバーレス向け！）
  hash_key     = "userId"          # パーティションキー（必須）
  range_key    = "todoId"          # ソートキー（オプション・必要なら書く）

  # キーに指定した項目の「型」を定義するよ
  # S = String(文字列), N = Number(数値), B = Binary(バイナリ)
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "todoId"
    type = "S"
  }

  # リソースの管理用にタグをつけておくと後で便利！
  tags = {
    Environment = "dev"
    Project     = "serverless-app"
  }
}
