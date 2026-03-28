# ============================================================
# Bedrockモジュール
# ============================================================
# ナレッジベース本体とS3データソースを定義する。
#
# 【差分取り込みについて】
# BedrockのStartIngestionJobは「差分同期（Incremental Sync）」がデフォルト動作。
# 前回のIngestionJob実行以降にS3で追加・変更・削除されたオブジェクトのみを処理する。
# （S3のETagとLast-Modifiedタイムスタンプを使って変更検知）
# → Terraform側で明示的な差分設定は不要。IngestionJobを起動するだけでよい。
#
# 【自動トリガーについて】→ lambda.tf を参照
# S3にファイルをアップロードしても自動的には同期されない。
# lambda.tf の EventBridge + Lambda により、S3変更時に自動でIngestionJobを起動する。
# ============================================================

# ------------------------------------------------------------
# Bedrockナレッジベース
# ベクトル検索型KBとして定義。埋め込みモデルにCohere多言語v3を使用。
# ストレージはOpenSearch Serverlessコレクション（vector_db）に接続。
# ------------------------------------------------------------
resource "aws_bedrockagent_knowledge_base" "obsidian_kb" {
  name     = "obsidian-knowledge-base"
  role_arn = var.role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      # 日本語テキスト対応の多言語埋め込みモデル
      embedding_model_arn = "arn:aws:bedrock:ap-northeast-1::foundation-model/cohere.embed-multilingual-v3"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = var.collection_arn
      vector_index_name = "obsidian-index"
      field_mapping {
        vector_field   = "bedrock-embedding"       # ベクトル値の格納フィールド
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK" # チャンク化されたテキスト
        metadata_field = "AMAZON_BEDROCK_METADATA"   # ファイル名などのメタデータ
      }
    }
  }
}

# ------------------------------------------------------------
# S3データソース
# ▼▼▼ 差分取り込みの設定はここ ▼▼▼
# StartIngestionJob実行時にS3の変更差分のみを自動検知して取り込む。
# data_deletion_policy = "DELETE"（デフォルト）により、
# S3から削除されたファイルはKBからも削除される。
# ------------------------------------------------------------
resource "aws_bedrockagent_data_source" "obsidian_s3" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.obsidian_kb.id
  name              = "obsidian-s3-datasource"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.bucket_arn
    }
  }
}
