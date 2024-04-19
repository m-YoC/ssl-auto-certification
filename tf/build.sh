#!/bin/bash

# 初期設定 --------------------------------------------------------------------

context="../source"
dockerfile="${context}/aws-lambda-py.dockerfile"
aws_repository=$(echo "local.lambda.ecr_repository" | terraform console | xargs)

tags=(latest)

buildx_platform="linux/amd64/v3,linux/arm64/v8"
archs=(amd64 arm64)


# -----------------------------------------------------------------------------
profile=$(echo "var.aws_profile" | terraform console -var-file aws-userdata.auto.tfvars | xargs)
AWS_ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"


# ログイン --------------------------------------------------------------------
aws ecr get-login-password --region $AWS_DEFAULT_REGION --profile $profile \
| docker login --username AWS --password-stdin $AWS_ECR_URI


# Multi Platform Build --------------------------------------------------------

# ビルダーインスタンスを作成して名前を覚えておく
builder_name=$(docker buildx create --use)
echo "docker buildx: create $builder_name"

# exit時にビルダーインスタンスの削除
trap "docker buildx rm $builder_name" EXIT

build="docker buildx build $context/ -f $dockerfile --no-cache --push"
# 対応プラットフォーム(CPUアーキテクチャ)の設定
build="$build --platform $buildx_platform"
# --attest type=provenance または --provenance=true は、
# ビルドの実行方法に関する情報を含むビルド結果の SLSA 来歴証明書を生成します。
# OCI イメージを作成する場合、デフォルトで最小限の出所証明書がイメージに含まれます。
# ビルド時にこれを無効にするには、明示的に--provenance=falseを設定します。
build="$build --provenance=false"

# タグの設定
for tag in "${tags[@]}"; do
    build="$build -t $AWS_ECR_URI/$aws_repository:$tag"
done

# 実行
$($build)


# Add Platform Tags -----------------------------------------------------------

# image indexにはタグ付けが成されているが，個別のimageにはタグが付けられていない
# それぞれのプラットフォームイメージにタグ付けを行っていく

# 各イメージのmanifest取得コマンド: 共通部分
aws_get_manifest="aws ecr batch-get-image --repository-name $aws_repository --output text --query images[].imageManifest --profile $profile"
# 各イメージのtag追加コマンド: 共通部分
aws_put_tag="aws ecr put-image --repository-name $aws_repository --profile $profile"

# manifest listの取得
manifest_list=$(docker manifest inspect $AWS_ECR_URI/$aws_repository:latest)
# echo $manifest_list

for arch in "${archs[@]}"; do
    digest=$(echo $manifest_list | jq -r ".manifests[] | select(.platform.architecture == \"$arch\")" | jq -r .digest)
    echo "$arch: $digest"

    manifest=$($aws_get_manifest --image-ids imageDigest=$digest)
    # echo "amd64: $amd64_manifest"
    # echo "get_manifest!"
    $($aws_put_tag --image-tag $arch --image-manifest "$manifest" > /dev/null)
done

