# Terraformとプロバイダーの設定
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWSプロバイダー
provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}
