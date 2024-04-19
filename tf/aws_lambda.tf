
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/../source/"
  output_path = "${path.module}/../source/aws_lambda.zip"
}

# ECRのコンテナイメージから起動する場合
resource "aws_lambda_function" "ssl_auto_cert" {
  function_name = "ssl-auto-certification"
  description   = "Certificates domain automatically and push to s3-bucket. (certbot / route53 / wildcard / Let's Encript)"
  # イメージの指定: Image ListはX
  package_type  = "Image"
  image_uri     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.lambda.ecr_registory}:arm64"
  architectures = ["arm64"] # Default is ["x86_64"]

  role = "arn:aws:iam::${var.aws_account_id}:role/${local.lambda.role_name}"
  # publish       = true

  # memoryが初期値の128MBだとaws-cliが動かないor遅すぎる. 512MBくらいがいい
  memory_size = 512
  timeout     = 180

  # アップデートのトリガーに使用されるハッシュ。
  # これが無いとコードを修正した際にterraformが検知できない。
  source_code_hash = filebase64sha256(data.archive_file.zip.output_path)

}

resource "aws_cloudwatch_log_group" "ssl_auto_cert" {
  name              = "/aws/lambda/${aws_lambda_function.ssl_auto_cert.function_name}"
  retention_in_days = 30
}
