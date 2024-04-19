
# SSL auto certification

### EN

### JP

aws Lambda上でcertbotを起動してroute53に登録されているドメインのLet's Encrypt証明書を自動発行します．
発行された証明書はaws S3 Bucketに保存されます． 
定期実行はaws EventBridgeのSchedulerで定義されます．

- Dockerコンテナ上にaws-cli, Terraform, Docker (Docker in Docker)作業環境を提供します．  
- awsのMFAを強制したAssume Roleによりセキュリティを高めています[^1]．
- Terraformで定期的な更新環境を自動構築します．
- `docker buildx`でamd64版とarm64版のDocker Imageを両方構築します．
    - 作成手続きは`build.sh`で自動化されています．
    - 片方不要なら`build.sh`を編集してください．

> [!NOTE]
> awsの一部のリソースは単純化と削除回避のためTerraformで管理されていません．各自で作成してください．  
> -> IAM User, IAM Role, S3 Bucket, ECR Repository, Schedule Group, Route53, 

> [!NOTE]
> 構造単純化のためバリデーションなどのエラー処理がされていません．必要な人は各自で行ってください．



## Tech, Keywords

- aws
    - aws-cli
    - lambda (using container image)
    - EventBridge scheduler 
    - Assume Role
- Terraform
- Docker
    - compose
    - Multi Stage Build
    - Docker in Docker
    - buildx
- certbot
    - dns-route53
- Let's Encrypt,


## Settings

```bash
$ make build
$ make up
```

```bash
# in Docker Container
$ aws-assume <profile-name> <MFA-Token> 
$ cd tf

# Check settings.
# -> build.sh, variables.tf...
$ make build
# Wait...

$ make tf-apply

# First Certification
$ make invoke
```

## envfile

load to compose.yml

```env:ssl.env
TF_VAR_DOMAINS='["example.com", "*.example.com"]'
TF_VAR_EMAIL='example@example.com'
TF_VAR_S3_BUCKET_NAME='example-bucket'
```

```env:aws.env
AWS_ACCESS_KEY_ID=EXAMPLEACCESSKEYSTRINGS
AWS_SECRET_ACCESS_KEY=ExAmpLsecRetEAcceSskeYSTrinGs
# AWS_SESSION_TOKEN=xxxxxxxxxxxxxxxxxxx
AWS_DEFAULT_REGION=ap-northeast-1 
AWS_DEFAULT_OUTPUT=json

AWS_ACCOUNT_ID="0123456789"
AWS_ROLE_ARN="arn:aws:iam::xxxxxxxxxxxx:role/Example-CLI-Role"
AWS_ROLE_EXTERNAL_ID="ExampleExternalID"
AWS_MFA_SERIAL_ARN="arn:aws:iam::xxxxxxxxxxxx:mfa/example-auth"
```

---

作成参考[^2][^3]

[^1]: [ryo0301, MacからAWSにアクセスする時はAssumeRoleすることにした, Qiita](https://qiita.com/ryo0301/items/0730e4b1068707a37c31)
[^2]: [id:cohalz, Let's Encrypt証明書の自動更新システムを作る, Hatena Developer Blog](https://developer.hatenastaff.com/entry/2018/12/11/133000)
[^3]: [id:cohalz, CertUpdater, GitHub](https://github.com/cohalz/CertUpdater)
