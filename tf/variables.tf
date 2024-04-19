
variable "aws_profile" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}


locals {
    lambda = {
        ecr_registory = "lambda/ssl-auto-certification"
        role_name = "Lambda-Role"
    }

    scheduler = {
        role_name = "EventBridge-Role"
    }
}


# 環境変数(TF_VAR_XXXX)で定義されている変数
variable "DOMAINS" {
    type = list(string)
}

variable "EMAIL" {
    type = string
}

variable "S3_BUCKET_NAME" {
    type = string
}

