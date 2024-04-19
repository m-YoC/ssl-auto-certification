import json
import boto3
from botocore.exceptions import ClientError
import subprocess

import sys
import os
import shutil

def awscli_install_test():
    return subprocess.run("./aws --version", shell=True, capture_output=True, text=True).stdout


def certbot_install_test():
    return subprocess.run("certbot --version", shell=True, capture_output=True, text=True).stdout


def install_test():
    return (awscli_install_test() + certbot_install_test()).replace("\n", " ")


def certbot_dir():
    return {"config": "/tmp/config-dir/", "work": "/tmp/work-dir/", "logs": "/tmp/logs-dir/"}


def clear_certbot_dir():
    if os.path.exists(certbot_dir()["config"]):
        shutil.rmtree(certbot_dir()["config"])
    if os.path.exists(certbot_dir()["work"]):
        shutil.rmtree(certbot_dir()["work"])
    if os.path.exists(certbot_dir()["logs"]):
        shutil.rmtree(certbot_dir()["logs"])


# certbot options:
#   certonly            : 証明書を取得または更新。インストールはしない
#   --non-interactive   : 非対話的に実行
#   --agree-tos         : ACMEサーバーのサブスクライバー契約に同意
#   --email             : 重要なアカウント通知のメールアドレス
#   --domains           : 証明書を取得するためのドメインのコンマ区切りリスト
#   --config-dir        : Configuration directory. (default: /etc/letsencrypt)
#   --work-dir          : Working directory. (default: /var/lib/letsencrypt)
#   --logs-dir          : Logs directory. (default: /var/log/letsencrypt)
#   --server            : ACME Directory Resource URI. (default: https://acme-v02.api.letsencrypt.org/directory)
#   --dry-run           : Test "renew" or "certonly" without saving any certificates to disk
def provision_certificate(domains, email, is_production=False):
    options  = f"certonly --non-interactive --agree-tos"
    options += f" --email {email}"
    options += f" --domains {",".join(domains)}"
    options += f" --config-dir {certbot_dir()["config"]}"
    options += f" --work-dir {certbot_dir()["work"]}"
    options += f" --logs-dir {certbot_dir()["logs"]}"
    options += f" --dns-route53"

    if is_production:
        options += f" --server https://acme-v02.api.letsencrypt.org/directory"
    else:
        options += f" --dry-run"

    print(f"run: certbot {options}")
    subprocess.run(f"certbot {options}", shell=True)
    return 


def copy_to_s3_bucket(bucket_name):
    if bucket_name[-1] != "/":
        bucket_name += "/"

    print(f"run: ./aws s3 cp {certbot_dir()["config"]} s3://{bucket_name} --recursive")
    subprocess.run(f"./aws s3 cp {certbot_dir()["config"]} s3://{bucket_name} --recursive", shell=True)
    return




def handler(event=None, context=None):
    clear_certbot_dir()
    
    try:
        domains       = event.get("domains")
        email         = event.get("email")
        is_production = event.get("is_production", False) 
        bucket_name   = event.get("s3_bucket")

        provision_certificate(domains, email, is_production)
        copy_to_s3_bucket(bucket_name)

        return {
            'statusCode': 200,
            'body': "Finish to provision certificates."
        }

    except ClientError as e:
        raise Exception(f"[failed] {e.response["Error"]["Message"]}")


    
