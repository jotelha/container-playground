#!/bin/bash
set -euxo pipefail

# https://lmod.readthedocs.io/en/latest/030_installing.html
VERSION=5.1.4.9
sudo mkdir -p /opt/apps/lua/${VERSION}
mkdir -p ${HOME}/src
cd ${HOME}/src
rm -rf lua-${VERSION}*
# https://www.lua.org/download.html
# curl -R -O http://www.lua.org/ftp/lua-${VERSION}.tar.gz
wget https://sourceforge.net/projects/lmod/files/lua-${VERSION}.tar.bz2
bunzip2 lua-${VERSION}.tar.bz2
tar xf lua-${VERSION}.tar
cd lua-${VERSION}
./configure --prefix=/opt/apps/lua/${VERSION}
make
sudo make install
cd /opt/apps/lua
sudo ln -s ${VERSION} lua
sudo mkdir -p /usr/local/bin
sudo ln -s /opt/apps/lua/lua/bin/lua /usr/local/bin
