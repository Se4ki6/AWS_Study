resource "aws_dynamodb_table" "vote_table" {
  name         = var.table_name      # 呼び出し元（dev等）から渡されるテーブル名
  billing_mode = "PAY_PER_REQUEST"   # 使った分だけ課金のオンデマンドモード
  hash_key     = "pollId"            # パーティションキー（アンケートのお題ID）
  range_key    = "optionId"          # ソートキー（選択肢のID）

  # キーとして使う項目の型定義（S = String/文字列）
  attribute {
    name = "pollId"
    type = "S"
  }

  attribute {
    name = "optionId"
    type = "S"
  }

  # リソース管理用のタグ
  tags = {
    Environment = var.environment    # 呼び出し元（dev等）から渡される環境名
    Project     = "voting-app"
  }
}