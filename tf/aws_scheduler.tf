
resource "aws_scheduler_schedule" "ssl_auto_cert" {
  name        = "domain-certification__${var.DOMAINS[0]}"
  group_name  = "ssl-auto-certification"
  description = "Certificates domain [${var.DOMAINS[0]}] automatically each month. (certbot / route53 / wildcard / Let's Encrypt)"

  flexible_time_window {
    # mode = "OFF"
    mode = "FLEXIBLE"
    # スケジュールを起動できる最大時間幅。1分から1440分まで。
    maximum_window_in_minutes = 60
  }

  # aws cron式のリファレンス
  # https://docs.aws.amazon.com/ja_jp/eventbridge/latest/userguide/eb-cron-expressions.html
  # schedule_expression = "rate(5 minutes)"
  schedule_expression          = "cron(0 04 1 * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  /* (Optional) 
    スケジュールがターゲットの起動を開始する日付をUTCで指定します。
    スケジュールの再帰式によっては、指定した開始日以降に呼び出しが発生する場合があります。
    EventBridge Schedulerは、ワンタイムスケジュールの開始日を無視します。
    例：2030-01-01T01:00:00Z。
    */
  # start_date = 
  # end_date = 

  target {
    arn      = aws_lambda_function.ssl_auto_cert.arn
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${local.scheduler.role_name}"

    input = jsonencode({
      domains       = var.DOMAINS,
      email         = var.EMAIL,
      s3_bucket     = var.S3_BUCKET_NAME,
      is_production = true
    })

    retry_policy {
      maximum_retry_attempts = 10
    }
  }


}
