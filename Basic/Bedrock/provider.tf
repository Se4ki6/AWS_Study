# ============================================================
# Provider / Terraform バージョン設定（ルートモジュール）
# ============================================================
# Terraform の provider ブロックはルートモジュールに置く必要がある。
# 子モジュール内の provider ブロックは他のモジュールに適用されないため、
# modules/Provider/ の provider ブロックはここに移動している。
# ============================================================

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
