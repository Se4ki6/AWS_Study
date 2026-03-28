# ============================================================
# 手動トリガー用 Lambda（差分取り込み）
# ============================================================
# S3にファイルをアップロードした後、以下のコマンドで手動実行する：
#
#   aws lambda invoke \
#     --function-name bedrock-ingestion-trigger \
#     --region ap-northeast-1 \
#     --profile <プロファイル名> \
#     /dev/null
#
# StartIngestionJob はデフォルトで差分同期のため、
# S3で追加・変更・削除されたファイルのみ処理される。
# ============================================================

# ------------------------------------------------------------
# Lambda関数のソースコード（インライン）
# 環境変数からKnowledgeBaseIdとDataSourceIdを取得して
# StartIngestionJobを呼び出す
# ------------------------------------------------------------
data "archive_file" "ingestion_trigger_zip" {
  type        = "zip"
  output_path = "${path.module}/ingestion_trigger.zip"

  source {
    filename = "index.py"
    content  = <<-EOF
import boto3
import os

def handler(event, context):
    client = boto3.client('bedrock-agent', region_name='ap-northeast-1')
    response = client.start_ingestion_job(
        knowledgeBaseId=os.environ['KNOWLEDGE_BASE_ID'],
        dataSourceId=os.environ['DATA_SOURCE_ID'],
    )
    job_id = response['ingestionJob']['ingestionJobId']
    print(f"Started ingestion job: {job_id}")
    return {"ingestionJobId": job_id}
EOF
  }
}

# ------------------------------------------------------------
# Lambda関数
# aws lambda invoke コマンドで手動起動する
# ------------------------------------------------------------
resource "aws_lambda_function" "ingestion_trigger" {
  function_name    = "bedrock-ingestion-trigger"
  role             = var.lambda_trigger_role_arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.ingestion_trigger_zip.output_path
  source_code_hash = data.archive_file.ingestion_trigger_zip.output_base64sha256

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.obsidian_kb.id
      DATA_SOURCE_ID    = aws_bedrockagent_data_source.obsidian_s3.data_source_id
    }
  }
}
