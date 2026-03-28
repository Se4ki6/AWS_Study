# ============================================================
# Provider設定
# ============================================================
# Webクローラー対応などBedrockの最新機能を使うため 5.x系が必要
# リージョンは東京（ap-northeast-1）固定

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}
