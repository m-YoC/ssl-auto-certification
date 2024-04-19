#!/bin/bash

# https://qiita.com/ryo0301/items/0730e4b1068707a37c31

set -e

session_name="cli-session-$1"
profile=$1
token_code=$2

external_id=$AWS_ROLE_EXTERNAL_ID

duration_sec=$((60*60*3))

cmd="aws sts assume-role"
cmd="$cmd --role-arn $AWS_ROLE_ARN --role-session-name $session_name"
cmd="$cmd --external-id $external_id --serial-number $AWS_MFA_SERIAL_ARN --token-code $token_code"
cmd="$cmd --duration-seconds $duration_sec"

creds=$($cmd)

access_key_id=$(echo $creds | jq --raw-output .Credentials.AccessKeyId)
secret_access_key=$(echo $creds | jq --raw-output .Credentials.SecretAccessKey)
session_token=$(echo $creds | jq --raw-output .Credentials.SessionToken)

# aws configure set region ap-northeast-1
aws configure set aws_access_key_id $access_key_id --profile $profile
aws configure set aws_secret_access_key $secret_access_key --profile $profile
aws configure set aws_session_token $session_token --profile $profile


# get timeout-date of aws assume-role session
timeout=$(echo "session timeout: $(date -d "$duration_sec seconds" "+%Y/%m/%d - %H:%M:%S [yyyy/mm/dd - hh:mm:ss]")")


echo ""
aws configure list --profile $profile
echo ""
echo $timeout | tee /$TFDIR/aws_assume_role_session_timeout_date.txt
echo ""

# -------------------------------------------------------------------------------


# create terraform variables - aws_profile, aws_account_id, aws_region
tfvars_filename="aws-userdata.auto.tfvars"
bind_directory_name="tf"

echo "aws_profile    = \"$profile\""             > /$TFDIR/$bind_directory_name/$tfvars_filename
echo "aws_account_id = \"$AWS_ACCOUNT_ID\""     >> /$TFDIR/$bind_directory_name/$tfvars_filename
echo "aws_region     = \"$AWS_DEFAULT_REGION\"" >> /$TFDIR/$bind_directory_name/$tfvars_filename

# copy
# cp /$TFDIR/$bind_directory_name/$tfvars_filename /$TFDIR/tf-ecr/
# cp /$TFDIR/$bind_directory_name/$tfvars_filename /$TFDIR/tf-lambda/

