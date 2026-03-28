# ============================================================
# S3モジュール
# ============================================================
# ナレッジベースのドキュメントデータ（Obsidianノートなど）を格納するバケット。
# バケット名にランダムIDを付与して名前衝突を防ぐ。

resource "aws_s3_bucket" "obsidian_data" {
  bucket = "my-sample-bedrock-data-${random_id.id.hex}"
}

resource "random_id" "id" {
  byte_length = 4
}

