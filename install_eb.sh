#!/bin/bash
set -euxo pipefail

# https://easybuild.readthedocs.io/en/latest/Installation.html
EASYBUILD_PREFIX=${HOME}/.local/easybuild
curl -O https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
python3 bootstrap_eb.py $EASYBUILD_PREFIX

# update $MODULEPATH, and load the EasyBuild module
module use $EASYBUILD_PREFIX/modules/all
module load EasyBuild
