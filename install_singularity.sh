#!/bin/bash

# https://sylabs.io/guides/3.5/user-guide/quick_start.html#quick-installation-steps
# accessed 2020/05/18
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup

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
