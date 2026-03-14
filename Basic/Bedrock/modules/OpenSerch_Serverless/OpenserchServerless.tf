data "aws_caller_identity" "current" {}

# IAMロールポリシー（S3・AOSS・Bedrockへのアクセス権限）
# ※ IAMロール自体はIAMモジュール、AOSSコレクションはこのモジュールにあるため
#    循環依存を避けるためここで定義
resource "aws_iam_role_policy" "bedrock_kb_policy" {
  name = "BedrockKnowledgeBasePolicy"
  role = var.role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.bucket_arn, "${var.bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["aoss:APIAccessAll"]
        Resource = [aws_opensearchserverless_collection.vector_db.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:ap-northeast-1::foundation-model/cohere.embed-multilingual-v3"]
      }
    ]
  })
}

# コレクション（箱）の作成
resource "aws_opensearchserverless_collection" "vector_db" {
  name = "obsidian-vector-db"
  type = "VECTORSEARCH"
}

# 暗号化ポリシー
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name = "obsidian-encryption-policy"
  type = "encryption"
  policy = jsonencode({
    Rules       = [{ Resource = ["collection/obsidian-vector-db"], ResourceType = "collection" }]
    AWSOwnedKey = true
  })
}

# ネットワークポリシー（パブリックアクセス許可 ※本番環境では絞ってね）
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

# データアクセスポリシー（Bedrockと、今Terraformを実行しているあなたに権限を付与）
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
    Principal = [
      var.role_arn,
      data.aws_caller_identity.current.arn
    ]
  }])
}
