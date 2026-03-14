# Bedrock Knowledge Base — Terraform

ObsidianノートをS3に置き、Amazon Bedrock Knowledge Baseとして検索・参照できるようにするインフラ構成です。

## アーキテクチャ

```
S3 Bucket (ノートデータ)
    │
    ▼
IAM Role (Bedrock用)
    │
    ▼
OpenSearch Serverless (ベクターDB)
    │
    ▼
Bedrock Knowledge Base ──► Data Source (S3)
```

## モジュール構成

```
Basic/Bedrock/
├── maim.tf               # ルート：モジュール配線
├── variable.tf           # ルート変数
├── terraform.tfvars      # 変数の値
└── modules/
    ├── Provider/         # AWSプロバイダ・バージョン設定
    ├── S3/               # データ格納バケット
    ├── IAM/              # Bedrock用IAMロール
    ├── OpenSerch_Serverless/  # AOSSコレクション + IAMポリシー
    └── Bedrock/          # Knowledge Base + Data Source
```

### 各モジュールの責務

| モジュール | 作成するリソース |
|---|---|
| Provider | `terraform` required_providers, `provider "aws"` |
| S3 | `aws_s3_bucket`, `random_id` |
| IAM | `aws_iam_role` (Bedrockサービス用) |
| OpenSearch_Serverless | `aws_iam_role_policy`, `aws_opensearchserverless_collection`, 暗号化/ネットワーク/データアクセスポリシー |
| Bedrock | `aws_bedrockagent_knowledge_base`, `aws_bedrockagent_data_source` |

### モジュール間の依存関係

```
Provider  S3
           │
           ├──► IAM
           │     │
           └─────┴──► OpenSearch_Serverless
                             │
                   IAM ──────┴──► Bedrock
```

循環依存を避けるため、`aws_iam_role_policy`（IAMロールポリシー）はIAMモジュールではなくOpenSearch_Serverlessモジュール内で定義しています。AOSSコレクションARNをポリシー内で参照する必要があるためです。

## 使用リソース

- **Amazon S3** — Obsidianノートの格納先
- **AWS IAM** — BedrockがS3・AOSS・基盤モデルにアクセスするためのロール/ポリシー
- **Amazon OpenSearch Serverless** — ベクター検索エンジン（コレクション名: `obsidian-vector-db`）
- **Amazon Bedrock Knowledge Base** — RAG用ナレッジベース
- **埋め込みモデル** — `cohere.embed-multilingual-v3`

## 前提条件

- Terraform `>= 1.0`
- AWS CLI設定済み (`~/.aws/credentials`)
- `ap-northeast-1` リージョンでBedrock基盤モデルのアクセス許可取得済み

## 使い方

### 1. 変数を設定

`terraform.tfvars` を編集します：

```hcl
aws_profile = "default"  # 使用するAWSプロファイル名
```

### 2. 初期化

```bash
terraform init
```

### 3. 確認

```bash
terraform plan
```

### 4. デプロイ

```bash
terraform apply
```

### 5. 削除

```bash
terraform destroy
```

## デプロイ後の手順

Bedrock Knowledge Baseはインフラを作成しただけでは検索できません。以下の手順が別途必要です：

1. **S3にデータをアップロード** — Obsidianの`.md`ファイルをバケットに配置
2. **OpenSearchインデックスを作成** — マネジメントコンソール or AWS CLIでインデックス `obsidian-index` を作成
3. **同期 (Sync) を実行** — BedrockコンソールからData Sourceの「Sync」を実行

## 変数一覧

| 変数名 | 説明 | デフォルト |
|---|---|---|
| `aws_profile` | 使用するAWSプロファイル名 | `"default"` |

## 注意事項

- OpenSearch Serverlessのネットワークポリシーは**パブリックアクセス許可**になっています。本番環境では `AllowFromPublic = false` にしてVPCエンドポイント等を設定してください。
- S3バケット名にはランダムIDが付与されます（例: `my-sample-bedrock-data-a1b2c3d4`）。
