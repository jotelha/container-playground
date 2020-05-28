#!/bin/bash
set -euxo pipefail

# https://sylabs.io/guides/3.5/admin-guide/installation.html
sudo yum update -y && \
     sudo yum groupinstall -y 'Development Tools' && \
     sudo yum install -y \
     openssl-devel \
     libuuid-devel \
     libseccomp-devel \
     wget \
     squashfs-tools \
     cryptsetup

mkdir -p ${HOME}/src
cd ${HOME}/src

# https://golang.org/dl/
export VERSION=1.14.3 OS=linux ARCH=amd64 && \  # Replace the values as needed
  wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \ # Downloads the required Go package
  sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \ # Extracts the archive
  rm go$VERSION.$OS-$ARCH.tar.gz
# sha256 93023778d4d1797b7bc6a53e86c3a9b150c923953225f8a48a2d5fabc971af56

# echo 'export PATH=/usr/local/go/bin:$PATH' >> $HOME/.bashrc && \
#  source $HOME/.bashrc
export PATH="/usr/local/go/bin:$PATH"

export VERSION=3.5.2 && \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-${VERSION}.tar.gz && \
    cd singularity

./mconfig && \
    make -C builddir && \
    sudo make -C builddir install
