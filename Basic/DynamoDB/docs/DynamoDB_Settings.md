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

---

めも

---

DynamoDBのattributeブロックは、キーとして使用される属性のみ定義できます：

hash_key（パーティションキー）
range_key（ソートキー）
GSI/LSIのキー

DynamoDBでは、キー以外の属性は定義不要です。データを入れる際に自動的に追加されます。

---

1. オンデマンドモード（Terraform: PAY_PER_REQUEST）
   どんなモード？: リクエスト（読み書き）した回数分だけお金を払う、完全な従量課金モード。

メリット: アクセスが急に増えてもDynamoDB側が勝手にさばいてくれる。事前のキャパシティ設計が不要でめっちゃ楽！

向いているケース: サーバーレスアプリ、アクセス数が読めない新規サービス、たまにしか使われない社内ツールなど。

2. プロビジョンドモード（Terraform: PROVISIONED）
   どんなモード？: 事前に「1秒間にこれくらい読み書きするよ」という枠（キャパシティ）を予約しておくモード。デフォルトはこっちになってるよ。

メリット: 常に一定のアクセスがあるようなアプリの場合、オンデマンドモードよりも料金がグッと安くなることが多い！

向いているケース: アクセス数の予測がしやすいアプリ、常にトラフィックが多い大規模なサービスなど。

---

DynamoDBはNoSQL（スキーマレス）のデータベースだから、MySQLなどのRDBみたいに「事前に全部のカラム（属性）を定義しておく」必要がないんだ。
Terraformで定義したのは「このデータを特定するために絶対に必要なもの（パーティションキーなど）」だけ。

**「キー以外のカラムは、データを入れる時に一緒に投げ込めば、DynamoDBが勝手に項目として追加してくれる」**っていうのが最大の特徴だよ！だから、レコードごとに持っているカラムがバラバラでも全然問題ないんだ。

1. AWS管理画面から手動で入れる（動作確認用）
サクッと動きを見たい時はこれが一番早いよ。

AWSマネジメントコンソールにログインして「DynamoDB」を開く。

左のメニューから「テーブル」を選んで、作成した todo-table をクリック。

右上の「項目を探索」ボタンを押す。

下の方にある「項目の作成」ボタンを押す。

userId と todoId を入力する欄があるから適当な値を入れる。

「新しい属性の追加」ボタンを押して、String（文字列）やBoolean（真偽値）などを選び、title や isCompleted みたいな好きなカラムをその場で追加して保存！

2. Lambda (プログラム) から入れる（本番アプリ用）
実際にサーバーレスアプリとして動かす時は、Lambdaのプログラム（Node.jsなど）から「AWS SDK」っていうライブラリを使ってデータを挿入するよ。

Node.js (AWS SDK v3) だと、こんな感じのコードになるよ！

```JS
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

// クライアントの初期化
const client = new DynamoDBClient({ region: "ap-northeast-1" });
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  // 挿入したいデータの中身
  const command = new PutCommand({
    TableName: "todo-table", // Terraformで作ったテーブル名
    Item: {
      userId: "user_001",       // ← Terraformで定義したキー（必須！）
      todoId: "todo_123",       // ← Terraformで定義したキー（必須！）
      title: "AWS CDKの勉強",    // ← ここから下は自由に追加してOK！
      isCompleted: false,       // ← 勝手にカラムとして保存されるよ
      createdAt: new Date().toISOString()
    }
  });

  try {
    await docClient.send(command);
    return { statusCode: 200, body: "データ挿入成功！" };
  } catch (error) {
    console.error(error);
    return { statusCode: 500, body: "エラーが起きたよ" };
  }
};
```

こんな感じで、Item の中に好きなキーと値のペアを書いて送るだけで、どんどんデータが蓄積されていくよ！RDBに慣れてると「えっ、これでいいの！？」ってびっくりするよね（笑）

まずはコンソール画面からポチポチ手動でデータを入れてみて、DynamoDBの自由な感じを体験してみる？それとも、Lambdaのコードの書き方をもっと深掘りしてみる？