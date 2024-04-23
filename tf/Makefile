
# Makefile variables

region:=$(shell echo "var.aws_region" | terraform console -var-file aws-userdata.auto.tfvars | xargs)
profile:=$(shell echo "var.aws_profile" | terraform console -var-file aws-userdata.auto.tfvars | xargs)
repository-name:=$(shell echo "local.lambda.ecr_registory" | terraform console | xargs)
lambda-function-name:=$(shell echo "aws_lambda_function.ssl_auto_cert.function_name" | terraform console | xargs)
payload:='{"domains": ${TF_VAR_DOMAINS}, "email": "${TF_VAR_EMAIL}", "s3_bucket": "${TF_VAR_S3_BUCKET_NAME}"}'
payload_prod:='{"domains": ${TF_VAR_DOMAINS}, "email": "${TF_VAR_EMAIL}", "s3_bucket": "${TF_VAR_S3_BUCKET_NAME}", "is_production": true}'


# ----------------------------------------------------------------------------------------------------------------------------------

###>
###> !  -- aws assume role command --
###>   aws-assume <profile-name> <MFA-one-time-password>
###> 

###> docker buildx (amd64/arm64)
build: ## Build docker images, push to private ECR registory, and set tags. #> Check parameters of build.sh.
	@./build.sh

###> aws ECR registory
ecr-del: ## Delete all untagged images.
	@aws ecr list-images --region ${region} --repository-name ${repository-name} --filter "tagStatus=UNTAGGED" --query "imageIds[*]" --profile ${profile} \
	| jq .[].imageDigest | xargs -I {} echo -n "imageDigest={} " \
	| xargs aws ecr batch-delete-image --region ${region} --repository-name ${repository-name} --profile ${profile} --image-ids > /dev/null || true


# ----------------------------------------------------------------------------------------------------------------------------------

###> aws lambda
# local test
IP:='192.168.11.22'
test1: ## (Dev) Invoke local aws lambda. #> dry-run
	@docker compose up -d --build && echo "" && sleep 1
	@curl -d ${payload} http://${IP}:9000/2015-03-31/functions/function/invocations | jq
	@sleep 1 && echo "" && docker compose down
test2: ## (Dev) Invoke uploaded aws lambda. #> dry-run
	aws lambda invoke --function-name ${lambda-function-name} --payload ${payload} output.txt --profile ${profile}


invoke: ## (Production) Invoke uploaded aws lambda. #> Use when you need an SSL certificate right away.
	aws lambda invoke --function-name ${lambda-function-name} --payload ${payload_prod} output.txt --profile ${profile}


# ----------------------------------------------------------------------------------------------------------------------------------

###> Terraform
tf-apply: ## Apply aws resources using Terraform.
	terraform apply -auto-approve
tf-destroy: ## Destroy aws resources using Terraform.
	terraform destroy -auto-approve

###>
assumed-time: ## Check session timeout date of assumed role.
	@cat ../aws_assume_role_session_timeout_date.txt
	@echo "\033[30m            now: $(shell date '+%Y/%m/%d - %H:%M:%S')\033[0m"
.DEFAULT_GOAL := help
help: ## Display this help screen
	@sed -n 2p mfhelp.awk | cut -c 2- | xargs -i grep -E '{}' $(MAKEFILE_LIST) | awk -f mfhelp.awk

