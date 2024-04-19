This-is:
	:

region:=$(shell echo "var.aws_region" | terraform console -var-file aws-userdata.auto.tfvars | xargs)
profile:=$(shell echo "var.aws_profile" | terraform console -var-file aws-userdata.auto.tfvars | xargs)
repository-name:=$(shell echo "local.lambda.ecr_repository" | terraform console | xargs)

build:
	@./build.sh

ecr-delete-untagged-images:
	@aws ecr list-images --region ${region} --repository-name ${repository-name} --filter "tagStatus=UNTAGGED" --query "imageIds[*]" --profile ${profile} \
	| jq .[].imageDigest | xargs -I {} echo -n "imageDigest={} " \
	| xargs aws ecr batch-delete-image --region ${region} --repository-name ${repository-name} --profile ${profile} --image-ids > /dev/null || true
ecr-del:
	@make ecr-delete-untagged-images

tf-apply:
	terraform apply -auto-approve
tf-destroy:
	terraform destroy -auto-approve

# ----------------------------------------------------------------------------------------------------------------------------------

lambda-function-name:=$(shell echo "aws_lambda_function.ssl_auto_cert.function_name" | terraform console | xargs)
payload:='{"domains": ${TF_VAR_DOMAINS}, "email": "${TF_VAR_EMAIL}", "s3_bucket": "${TF_VAR_S3_BUCKET_NAME}"}'

# test using uploaded lambda function
test1:
	aws lambda invoke --function-name ${lambda-function-name} output.txt --profile ${profile}
test2:
	aws lambda invoke --function-name ${lambda-function-name} --payload ${payload} output.txt --profile ${profile}

# local test
IP:='192.168.11.22'
test3:
	@docker compose up -d --build && echo "" && sleep 1
	@curl -d ${payload} http://${IP}:9000/2015-03-31/functions/function/invocations | jq
	@sleep 1 && echo "" && docker compose down

payload_prod:='{"domains": ${TF_VAR_DOMAINS}, "email": "${TF_VAR_EMAIL}", "s3_bucket": "${TF_VAR_S3_BUCKET_NAME}", "is_production": true}'

invoke:
	aws lambda invoke --function-name ${lambda-function-name} --payload ${payload_prod} output.txt --profile ${profile}

