# DynamoDB (Terraform) 設定書

### データベース (`dynamodb.tf`)

- テーブル名の定義（環境名をプレフィックスとして付与する）
- キャパシティモードの設定（サーバーレス構成のため `PAY_PER_REQUEST` を指定）
- 必須キー（パーティションキー・ソートキー）の属性定義

```terraform
resource "aws_dynamodb_table" "todo_table" {
  name         = "todo-table"      # テーブル名
  billing_mode = "PAY_PER_REQUEST" # オンデマンドモード（サーバーレス向け！）
  hash_key     = "userId"          # パーティションキー（必須）
  range_key    = "todoId"          # ソートキー（オプション・必要なら書く）
```

- 検索要件に応じたセカンダリインデックス（GSI / LSI）の定義
- ※注意: スキーマレスのため、キー以外の属性はTerraform上には定義しない

```terraform
  # キーに指定した項目の「型」を定義する
  # S = String(文字列), N = Number(数値), B = Binary(バイナリ)
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "todoId"
    type = "S"
  }
```

- タグ
  - リソース管理が後で楽になる

```terraform
  # リソースの管理用にタグをつけておくと後で便利！
  tags = {
    Environment = "dev"
    Project     = "serverless-app"
  }
}
```

### 出力 (`outputs.tf`)

```terraform
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.todo_table.name
  description = "DynamoDBテーブル名"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.todo_table.arn
  description = "DynamoDBテーブルのARN"
}
```
