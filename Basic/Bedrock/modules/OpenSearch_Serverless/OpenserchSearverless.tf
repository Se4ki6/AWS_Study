# ============================================================
# OpenSearch Serverlessモジュール
# ============================================================
# Bedrockナレッジベースのベクトルデータ格納先（ベクトルDB）を構築する。
# 以下の4リソースをセットで作成する必要がある：
#   1. コレクション（箱）
#   2. 暗号化ポリシー（コレクション作成の必須条件）
#   3. ネットワークポリシー（アクセス元の制御）
#   4. データアクセスポリシー（操作権限の制御）
# ============================================================

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------
# IAMロールポリシー（S3・AOSS・Bedrockへのアクセス権限）
# BedrockナレッジベースのIAMロール（IAMモジュール）にアタッチする。
# ※ AOSSコレクションのARNが必要なためこのモジュールで定義。
#    IAMモジュールで定義するとAOSS ARN取得前に循環依存が発生するためここに置く。
# ------------------------------------------------------------
resource "aws_iam_role_policy" "bedrock_kb_policy" {
  name = "BedrockKnowledgeBasePolicy"
  role = var.role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3バケット内のドキュメント読み取り権限
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
      },
      {
        # ベクトルDBコレクションへの書き込み権限
        Effect   = "Allow"
        Action   = ["aoss:APIAccessAll"]
        Resource = [aws_opensearchserverless_collection.vector_db.arn]
      },
      {
        # Cohereによるテキスト→ベクトル変換（埋め込み生成）権限
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:ap-northeast-1::foundation-model/cohere.embed-multilingual-v3"]
      },
      {
        # AWSマーケットプレイスモデル（Cohere）の購読確認権限
        # マーケットプレイス経由のモデルはこの権限がないと初回呼び出し時にAccessDeniedになる
        Effect   = "Allow"
        Action   = ["aws-marketplace:ViewSubscriptions", "aws-marketplace:Subscribe"]
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------
# ベクトルDBコレクション（箱）
# type = "VECTORSEARCH" でベクトル検索特化型コレクションを作成
# ------------------------------------------------------------
resource "aws_opensearchserverless_collection" "vector_db" {
  name = "obsidian-vector-db"
  type = "VECTORSEARCH"

  # 暗号化・ネットワークポリシーが先に存在しないとコレクション作成が失敗する
  depends_on = [
    aws_opensearchserverless_security_policy.encryption_policy,
    aws_opensearchserverless_security_policy.network_policy,
  ]
}

# ------------------------------------------------------------
# 暗号化ポリシー
# AWS管理キー（AWSOwnedKey）でコレクションを暗号化
# コレクション作成前に必須
# ------------------------------------------------------------
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name = "obsidian-encryption-policy"
  type = "encryption"
  policy = jsonencode({
    Rules       = [{ Resource = ["collection/obsidian-vector-db"], ResourceType = "collection" }]
    AWSOwnedKey = true
  })
}

# ------------------------------------------------------------
# ネットワークポリシー
# ダッシュボード・コレクションへのパブリックアクセスを許可
# ※ 本番環境ではVPCエンドポイントに絞ることを推奨
# ------------------------------------------------------------
resource "aws_opensearchserverless_security_policy" "network_policy" {
  name = "obsidian-network-policy"
  type = "network"
  policy = jsonencode([{
    Rules = [
      { Resource = ["collection/obsidian-vector-db"], ResourceType = "dashboard" },
      { Resource = ["collection/obsidian-vector-db"], ResourceType = "collection" }
    ]
    AllowFromPublic = true
  }])
}

# ------------------------------------------------------------
# データアクセスポリシー
# 以下の2プリンシパルにインデックス操作権限を付与：
#   - BedrockナレッジベースのIAMロール（IngestionJob実行者）
#   - Terraformを実行しているIAMユーザー/ロール（手動操作用）
# ------------------------------------------------------------
resource "aws_opensearchserverless_access_policy" "data_policy" {
  name = "obsidian-data-policy"
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection",
        Resource     = ["collection/obsidian-vector-db"],
        Permission   = ["aoss:CreateCollectionItems", "aoss:DeleteCollectionItems", "aoss:UpdateCollectionItems", "aoss:DescribeCollectionItems"]
      },
      {
        ResourceType = "index",
        Resource     = ["index/obsidian-vector-db/*"],
        Permission   = ["aoss:CreateIndex", "aoss:DeleteIndex", "aoss:UpdateIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:WriteDocument"]
      }
    ],
    # ▼▼▼ データアクセスポリシーのPrincipal一覧 ▼▼▼
    # SSOユーザーの assumed-role ARN（arn:aws:sts::...:assumed-role/...）は
    # OpenSearch Serverlessダッシュボードでは認証されないため、
    # IAMユーザー（operator_iam_user_arn）を別途追加している。
    Principal = compact([
      var.role_arn,
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/${regex("assumed-role/([^/]+)/", data.aws_caller_identity.current.arn)[0]}",
      var.operator_iam_user_arn
    ])
  }])
}
