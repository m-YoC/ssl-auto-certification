
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# リージョンの指定
provider "aws" {
  region = var.aws_region

  # 必要なら接続アカウントの設定
  profile = var.aws_profile
}