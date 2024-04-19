
ARG TIMEZONE=Asia/Tokyo

ARG DOCKER_KEYRING_PATH="/etc/apt/keyrings/docker.asc"
ARG DOCKER_APT_LIST_PATH="/etc/apt/sources.list.d/docker.list"

ARG TF_KEYRING_PATH="/etc/apt/keyrings/hashicorp.gpg"
ARG TF_APT_LIST_PATH="/etc/apt/sources.list.d/hashicorp.list"


# -----------------------------------------------------------------------
# ubuntu ver: 14.04, 16.04, 18.04, 20.04, 21.10, 22.04
FROM ubuntu:22.04 AS docker
ARG TIMEZONE
ARG DOCKER_KEYRING_PATH
ARG DOCKER_APT_LIST_PATH
ARG DOCKER_URI="https://download.docker.com/linux/ubuntu"

# 環境のインストール
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE \
    apt-get install -y --no-install-recommends \ 
    curl ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Docker's official GPG key:
RUN curl -fsSL $DOCKER_URI/gpg -o $DOCKER_KEYRING_PATH

# Add the repository to Apt sources:
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_KEYRING_PATH] \ 
    $DOCKER_URI $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee $DOCKER_APT_LIST_PATH

# Install
# apt-get update && apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# In compose.yml
# volumes:
#      - "/var/run/docker.sock:/var/run/docker.sock"

# -----------------------------------------------------------------------
# ubuntu ver: 14.04, 16.04, 18.04, 20.04, 21.10, 22.04
FROM ubuntu:22.04 AS terraform
ARG TIMEZONE
ARG TF_KEYRING_PATH
ARG TF_APT_LIST_PATH
ARG TF_URI="https://apt.releases.hashicorp.com"

# 環境のインストール
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE \
    apt-get install -y --no-install-recommends \ 
    wget curl gnupg software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install the HashiCorp GPG key.
RUN wget -O- $TF_URI/gpg | gpg --dearmor -o $TF_KEYRING_PATH

# Verify the key's fingerprint.
RUN gpg --no-default-keyring --keyring $TF_KEYRING_PATH --fingerprint

# Add the official HashiCorp repository to your system. 
# The lsb_release -cs command finds the distribution release codename 
# for your current system, such as buster, groovy, or sid.
RUN echo "deb [signed-by=$TF_KEYRING_PATH] $TF_URI $(lsb_release -cs) main" | \
    tee $TF_APT_LIST_PATH

# Install
# apt-get update &&apt-get install terraform

# -----------------------------------------------------------------------
FROM ubuntu:22.04 AS aws-cli
ARG TIMEZONE

# aws-cliのインストール
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE \ 
    apt-get install -y --no-install-recommends \ 
    python3-pip awscli jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install awscli --upgrade --user
COPY ./aws-assume-role.sh /usr/local/bin/aws-assume


# -----------------------------------------------------------------------
FROM aws-cli AS aws-tf-test
ARG TIMEZONE
ARG DOCKER_KEYRING_PATH
ARG DOCKER_APT_LIST_PATH
ARG TF_KEYRING_PATH
ARG TF_APT_LIST_PATH

COPY --from=docker      $DOCKER_KEYRING_PATH    $DOCKER_KEYRING_PATH
COPY --from=docker      $DOCKER_APT_LIST_PATH   $DOCKER_APT_LIST_PATH
COPY --from=terraform   $TF_KEYRING_PATH        $TF_KEYRING_PATH
COPY --from=terraform   $TF_APT_LIST_PATH       $TF_APT_LIST_PATH

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=$TIMEZONE \ 
    apt-get install -y --no-install-recommends \ 
    make curl \ 
    terraform \ 
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# その他設定
ARG WORKDIR="test"
RUN mkdir /$WORKDIR && umask 0000
WORKDIR /$WORKDIR

ENV TFDIR=$WORKDIR
ENV TZ=$TIMEZONE

