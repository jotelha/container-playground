#!/bin/bash
set -euxo pipefail

sudo yum install -y tcl-devel

# https://lmod.readthedocs.io/en/latest/030_installing.html
VERSION=8.2
mkdir -p ${HOME}/src
cd ${HOME}/src
rm -rf Lmod-${VERSION}*
wget https://sourceforge.net/projects/lmod/files/Lmod-${VERSION}.tar.bz2
bunzip2 Lmod-${VERSION}.tar.bz2
tar xf Lmod-${VERSION}.tar
cd Lmod-${VERSION}
./configure --prefix=/opt/apps
sudo make install

sudo ln -fs /opt/apps/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
sudo ln -fs /opt/apps/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
# sudo ln -s /opt/apps/lmod/lmod/init/profile.fish   /etc/fish/conf.d/z00_lmod.fish
