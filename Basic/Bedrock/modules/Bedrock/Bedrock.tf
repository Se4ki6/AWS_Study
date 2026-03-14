resource "aws_bedrockagent_knowledge_base" "obsidian_kb" {
  name     = "obsidian-knowledge-base"
  role_arn = var.role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:ap-northeast-1::foundation-model/cohere.embed-multilingual-v3"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = var.collection_arn
      vector_index_name = "obsidian-index"
      field_mapping {
        vector_field   = "bedrock-embedding"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

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
