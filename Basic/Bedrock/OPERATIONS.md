# Bedrock ナレッジベース 運用ドキュメント

## アーキテクチャ概要

```
[Obsidianノート等] → S3バケット
                         │ (Object Created / Deleted イベント)
                         ↓
                    EventBridge ルール
                         │
                         ↓
                    Lambda (bedrock-ingestion-trigger)
                         │ StartIngestionJob (差分のみ)
                         ↓
                    Bedrock Knowledge Base
                         │ ベクトル変換 (Cohere Embed Multilingual v3)
                         ↓
                    OpenSearch Serverless (obsidian-vector-db)
```

---

## 初回セットアップ手順

### 前提
- AWS CLI 設定済み（`~/.aws/credentials` に `AdministratorAccess-339126664118` プロファイルあり）
- Terraform インストール済み
- Python 仮想環境 (`.venv`) セットアップ済み

### 手順1: Cohereモデルアクセスを有効化（コンソール・初回のみ）

```
AWSコンソール（sub_Se4ki6 でログイン）
→ Amazon Bedrock → モデルアクセス
→「使用可能なモデルを管理」
→ Cohere Embed Multilingual v3 にチェック → 保存
```

### 手順2: Terraform デプロイ

```powershell
cd C:\Users\sksrd\Programing\AWS\Basic\Bedrock

terraform init    # 初回のみ
terraform plan    # 差分確認
terraform apply   # デプロイ
```

### 手順3: OpenSearch Serverless にベクトルインデックスを作成（コンソール・初回のみ）

**⚠️ この手順を省略すると Bedrock の apply が失敗します**

`sub_Se4ki6` でコンソールにログインし、以下のPythonスクリプトを実行：

```powershell
# コレクションエンドポイントを確認
# AWSコンソール → OpenSearch Service → Serverless → Collections
# → obsidian-vector-db → コレクションエンドポイント をコピー

pip install requests requests-aws4auth boto3

python - <<'EOF'
import boto3, requests
from requests_aws4auth import AWS4Auth

profile  = "AdministratorAccess-339126664118"
region   = "ap-northeast-1"
endpoint = "<コレクションエンドポイントURLをここに貼る>"

session  = boto3.Session(profile_name=profile)
creds    = session.get_credentials().get_frozen_credentials()
auth     = AWS4Auth(creds.access_key, creds.secret_key, region, "aoss", session_token=creds.token)

body = {
    "settings": {"index.knn": True},
    "mappings": {
        "properties": {
            "bedrock-embedding": {
                "type": "knn_vector",
                "dimension": 1024,
                "method": {"name": "hnsw", "engine": "faiss"}
            },
            "AMAZON_BEDROCK_TEXT_CHUNK": {"type": "text"},
            "AMAZON_BEDROCK_METADATA":   {"type": "text"}
        }
    }
}

r = requests.put(f"{endpoint}/obsidian-index", auth=auth, json=body,
                 headers={"Content-Type": "application/json"})
print(r.status_code, r.json())
# {"acknowledged": true} が返れば成功
EOF
```

### 手順4: Bedrock ナレッジベースを apply（手順3の後）

```powershell
terraform apply
```

---

## 日常運用

### ドキュメントをナレッジベースに追加・更新する

S3にファイルをアップロードするだけで自動的にナレッジベースへ取り込まれます。

```powershell
# バケット名を確認
terraform output

# ファイルをアップロード（自動でIngestionJobが起動）
aws s3 cp <ファイルパス> s3://<バケット名>/ --profile AdministratorAccess-339126664118

# フォルダごとアップロード
aws s3 sync <フォルダパス>/ s3://<バケット名>/ --profile AdministratorAccess-339126664118
```

アップロード後、数秒〜数十秒以内に EventBridge → Lambda → IngestionJob が自動起動します。

### ドキュメントをナレッジベースから削除する

```powershell
# S3から削除するとKBからも自動で削除される
aws s3 rm s3://<バケット名>/<ファイル名> --profile AdministratorAccess-339126664118
```

---

## 取り込み状況の確認

### IngestionJob の実行状況を確認

```powershell
# ナレッジベースIDとデータソースIDを取得
terraform output

# 実行履歴を確認
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id <KNOWLEDGE_BASE_ID> \
  --data-source-id <DATA_SOURCE_ID> \
  --region ap-northeast-1 \
  --profile AdministratorAccess-339126664118
```

| status | 意味 |
|--------|------|
| `STARTING` | 起動中 |
| `IN_PROGRESS` | 取り込み中 |
| `COMPLETE` | 完了 |
| `FAILED` | 失敗（詳細は `failureReasons` を確認） |

### Lambda の実行ログを確認

```powershell
aws logs tail /aws/lambda/bedrock-ingestion-trigger \
  --follow \
  --region ap-northeast-1 \
  --profile AdministratorAccess-339126664118
```

### 手動で IngestionJob を起動する（自動トリガーが動かない場合）

```powershell
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id <KNOWLEDGE_BASE_ID> \
  --data-source-id <DATA_SOURCE_ID> \
  --region ap-northeast-1 \
  --profile AdministratorAccess-339126664118
```

---

## Terraform 構成の変更・再デプロイ

```powershell
cd C:\Users\sksrd\Programing\AWS\Basic\Bedrock

terraform plan    # 変更差分を確認
terraform apply   # 適用
```

### 注意事項

- **OpenSearch のインデックスは Terraform 管理外**です。`terraform destroy` 後に再 apply する場合は「手順3: インデックス作成」を再実行してください。
- Bedrockモジュールは `depends_on = [module.OpenSearch_Serverless]` で依存関係を制御していますが、インデックス作成は自動化されていません。

---

## IAM アカウントの使い分け

| アカウント | 用途 |
|-----------|------|
| `sso_Se4ki6` | Terraform の実行（AWS SSO）。IAMユーザーログイン不可 |
| `sub_Se4ki6` | AWSコンソール操作・OpenSearch Dashboardsアクセス（IAMユーザー） |

### OpenSearch Dashboards にアクセスする（インデックス確認・クエリ）

`sub_Se4ki6` でAWSコンソールにログイン後：

```
Amazon OpenSearch Service → Serverless → Collections
→ obsidian-vector-db → OpenSearch Dashboards URL をクリック
```

---

## 差分取り込みの仕組み（詳細）

```
【なぜ差分だけ取り込めるか】
Bedrock の StartIngestionJob はデフォルトで差分同期（Incremental Sync）。
前回のIngestionJob以降にS3で変更されたオブジェクトのみを処理する。
（S3のETagとLast-Modifiedで変更を検知）

【トリガーの導線】
s3.tf  : aws_s3_bucket_notification.eventbridge
           └─ S3イベントをEventBridgeに転送する設定

lambda.tf: aws_cloudwatch_event_rule.s3_change
           └─ "Object Created" / "Object Deleted" を検知
           └─ バケット名でフィルタリング（自分のバケット以外は無視）

         aws_lambda_function.ingestion_trigger
           └─ StartIngestionJob を呼び出す
           └─ KNOWLEDGE_BASE_ID / DATA_SOURCE_ID は環境変数で注入済み
```

---

## トラブルシューティング

### IngestionJob が FAILED になる

1. Lambdaログを確認する（上記「Lambda の実行ログを確認」）
2. Bedrockのロール（`BedrockKnowledgeBaseRole-xxxx`）にS3・AOSSの権限があるか確認
3. OpenSearchインデックス（`obsidian-index`）が存在するか確認

### S3にアップロードしてもIngestionJobが起動しない

1. S3バケットのEventBridge通知が有効か確認
   ```powershell
   aws s3api get-bucket-notification-configuration \
     --bucket <バケット名> \
     --profile AdministratorAccess-339126664118
   # "EventBridgeConfiguration": {} が返ればOK
   ```
2. EventBridgeルール（`bedrock-s3-change-rule`）が有効か確認
3. LambdaにEventBridgeからの実行権限があるか確認

### Terraform apply で "no such index" エラー

OpenSearchインデックスが作成されていません。「手順3: インデックス作成」を実行してから再度 apply してください。

### OpenSearch Dashboards に "You don't have authorization" と表示される

`sub_Se4ki6`（IAMユーザー）でログインしているか確認してください。`sso_Se4ki6`（SSO）ではダッシュボードにアクセスできません。
