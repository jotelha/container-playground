#!/bin/bash
set -euxo pipefail

# https://docs.docker.com/engine/install/centos/
sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce docker-ce-cli containerd.io
# GPG key: 060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35

sudo systemctl start docker

# https://docs.docker.com/compose/install/
# accessed: 2020/05/18
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
