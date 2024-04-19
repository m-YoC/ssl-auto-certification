locals {
  # 実際には権限周りの関係で以下のロールやポリシーは今回はTerraformでは作成しない
  # コンソールを使用するか作成系の権限を持つロールを用意してから作成すること

  # lambdaにアタッチするロールのポリシー
  lambda_role_policy = <<POLICY
  {
		"Version": "2012-10-17",
		"Statement": [
			{
				"Sid": "",
				"Effect": "Allow",
				"Action": "sts:AssumeRole",
				"Principal": {
					"Service": "lambda.amazonaws.com"
				}
			}
		]
  }
  POLICY

  # lambdaに実際に持たせる権限
  # arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogsでもよさげ
  # assume roleの方にもCloudWatch Logsの権限が必要
  lambda_policy = <<POLICY
	{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "{aws_cloudwatch_log_group.example_log_group.arn}",
          "{aws_cloudwatch_log_group.example_log_group.arn}:*"
        ]
      }
    ]
  }
	POLICY
}


