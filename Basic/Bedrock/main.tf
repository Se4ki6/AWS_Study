# ============================================================
# Bedrockナレッジベース 全体構成
# ============================================================
#
# 【モジュール依存関係】
#
#   Provider
#     └─ AWSプロバイダの設定（リージョン・プロファイル）
#
#   S3
#     └─ ナレッジベースのデータ格納バケット
#
#   IAM
#     └─ S3.random_id_hex を受け取り、Bedrockが使うIAMロールを作成
#     └─ Lambda実行用IAMロールも作成（StartIngestionJob権限付き）
#
#   OpenSearch_Serverless
#     └─ IAM.role_arn / role_id を受け取りポリシーをアタッチ
#     └─ S3.bucket_arn を受け取りS3アクセス権限を付与
#     └─ ベクトルDBコレクションを作成
#
#   Bedrock
#     └─ IAM.role_arn を受け取りKnowledge Baseを作成
#     └─ OpenSearch_Serverless.collection_arn でベクトルDB接続先を設定
#     └─ S3.bucket_arn を受け取りデータソースを設定
#     └─ 手動トリガー用Lambda（aws lambda invoke で起動）を含む
#     └─ depends_on でOpenSearch_Serverlessの完了後に作成
# ============================================================

# Provider設定はルートの provider.tf で行うため、Providerモジュールは不要

module "S3" {
  source = "./modules/S3"
}

module "IAM" {
  source        = "./modules/IAM"
  random_id_hex = module.S3.random_id_hex
}

module "OpenSearch_Serverless" {
  source     = "./modules/OpenSearch_Serverless"
  role_arn   = module.IAM.role_arn
  role_id    = module.IAM.role_id
  bucket_arn = module.S3.bucket_arn
  # ▼▼▼ ダッシュボードアクセス用IAMユーザー（SSOではダッシュボード不可のため追加） ▼▼▼
  operator_iam_user_arn = var.operator_iam_user_arn
}

module "Bedrock" {
  source         = "./modules/Bedrock"
  role_arn       = module.IAM.role_arn
  collection_arn = module.OpenSearch_Serverless.collection_arn
  bucket_arn     = module.S3.bucket_arn
  lambda_trigger_role_arn = module.IAM.lambda_trigger_role_arn
  depends_on              = [module.OpenSearch_Serverless]
}
