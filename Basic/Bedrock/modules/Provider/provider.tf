# プロバイダの設定（Webクローラー対応のため最新版の5.x系を使ってね！）
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
