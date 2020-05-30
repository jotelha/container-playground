.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

# general
PREFIX := /mnt/dat
APPS_ROOT := $(PREFIX)/opt/apps
SOURCES_DIR := $(PREFIX)/src
SYSTEM_PROFILE_D := /etc/profile.d
# system-dependent fixed
SYSTEM_BIN := /usr/bin
# system-dependent fixed
SYSTEM_LOCAL := /usr/local
SYSTEM_LOCAL_BIN := $(SYSTEM_LOCAL)/bin
# system-dependent fixed
SYSTEM_BASHRC := /etc/bashrc
MAKE_EXE := $(SYSTEM_BIN)/make
# system-dependent fixed
PYTHON_EXE := $(SYSTEM_BIN)/python3
# system-dependent fixed

# Lua-realted
LUA_VERSION := 5.1.4.9
LUA_ROOT := $(APPS_ROOT)/lua/lua
# fixed
LUA_EXE := $(LUA_ROOT)/bin/lua
# fixed

# Lmod-related
LMOD_VERSION := 8.2
LMOD_INSTALL_PREFIX := $(APPS_ROOT)
LMOD_ROOT := $(LMOD_INSTALL_PREFIX)/lmod/lmod
# fixed
LMOD_EXE := $(LMOD_ROOT)/libexec/lmod
# fixed
LMOD_MODULES_ROOT := $(LMOD_ROOT)/modulefiles
# fixed

# DEVEL_MODULE_DIR := $(MODULES_ROOT)/all/Devel
# DEVEL_MODULE_FILE := $(DEVEL_MODULE_DIR)/InstallSoftware.lua

# eb-related
EB_VERSION := 4.2.1
EB_ROOT := $(PREFIX)/opt/easybuild
EB_EXE := $(EB_ROOT)/software/EasyBuild/$(EB_VERSION)/bin/eb
# fixed
EB_MODULES_ROOT := $(EB_ROOT)/modules/all
# fixed

EB_STAGE := 2019a
EB_GIT_REPO_ROOT := $(EB_ROOT)/git

# Docker-related
# TODO: specific version
DOCKER_COMPOSE_VERSION := 1.25.5
DOCKER_EXE := $(SYSTEM_BIN)/docker
# fixed

# Podman-related
# TODO: specific version
PODMAN_EXE := $(SYSTEM_BIN)/podman
# fixed

# Go-related
GO_VERSION := 1.14.3

# Singularity-related
SINGULARITY_VERSION := 3.5.2
SINGULARITY_EXE := $(SYSTEM_LOCAL_BIN)/singularity

.PHONY: all
all: $(wildcard install-*)

.PHONY: install-docker
install-docker: $(DOCKER_EXE)

.PHONY: install-podman
install-podman: $(PODMAN_EXE)

.PHONY: install-singularity
install-singularity: $(SINGULARITY_EXE)

# .PHONY: install-devel-mod
# install-devel-mod: $(DEVEL_MODULE_FILE)

.PHONY: configure-eb
configure-eb: install-eb eb_env.sh eb-repositories

.PHONY: install-eb
install-eb: $(EB_EXE)

.PHONY: install-lmod
install-lmod: $(LMOD_EXE)

# podman
.ONESHELL:
$(PODMAN_EXE): $(MAKE_EXE)
    #!/bin/bash
    set -euxo pipefail
    # CentOS 8
    sudo dnf -y module disable container-tools
    sudo dnf -y install 'dnf-command(copr)'
    sudo dnf -y copr enable rhcontainerbot/container-selinux
    sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
    sudo dnf -y install podman

# go & singularity
.ONESHELL:
$(GO_EXE):
    set -euxo pipefail
    # actually, no sources, just binary package
    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR)
    # https://golang.org/dl/
    VERSION=$(GO_VERSION) OS=linux ARCH=amd64  # Replace the values as needed
    wget https://dl.google.com/go/go$$VERSION.$$OS-$$ARCH.tar.gz  # Downloads the required Go package
    sudo tar -C $(SYSTEM_LOCAL) -xzvf go$$VERSION.$$OS-$$ARCH.tar.gz  # Extracts the archive
    rm go$$VERSION.$$OS-$$ARCH.tar.gz
    # sha256 93023778d4d1797b7bc6a53e86c3a9b150c923953225f8a48a2d5fabc971af56
    # echo 'export PATH=/usr/local/go/bin:$PATH' >> $HOME/.bashrc && \
    #  source $HOME/.bashrc
    LINE='export PATH="$(SYSTEM_LOACL)/go/bin:$$PATH"'
    FILE=$(SYSTEM_BASHRC)
    MSG="Added following line to $$FILE, rerun 'source $$FILE' in your current shell session."
    grep -qF -- "$$LINE" "$$FILE" || echo "$$LINE" >> "$$FILE"
    @echo $$MSG
    @echo $$LINE

.ONESHELL:
$(SINGULARITY_EXE): $(MAKE_EXE)
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

    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR)

    VERSION=$(SINGULARITY_VERSION)
    wget https://github.com/sylabs/singularity/releases/download/v$${VERSION}/singularity-$${VERSION}.tar.gz
    tar -xzf singularity-$${VERSION}.tar.gz
    source $(SYSTEM_BASHRC)
    cd singularity
    ./mconfig
    make -C builddir
    sudo make -C builddir install

# docker
.ONESHELL:
$(DOCKER_EXE): $(MAKE_EXE)
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
    sudo curl -L "https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/docker-compose-$$(uname -s)-$$(uname -m)" -o $(SYSTEM_LOCAL_BIN)/docker-compose
    sudo chmod +x $(SYSTEM_LOCAL_BIN)/docker-compose


# $(DEVEL_MODULE_FILE): $(EB_ROOT)
#    mkdir -p $(DEVEL_MODULE_DIR)
#    cp eb/InstallSoftware.lua $(DEVEL_MODULE_FILE)

# easybuild
.ONESHELL:
$(EB_EXE): $(LMOD_EXE) $(PYTHON_EXE)
    set -euxo pipefail
    # https://easybuild.readthedocs.io/en/latest/Installation.html
    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR)
    curl -O https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
    python3 bootstrap_eb.py $(EB_ROOT)
    # update $MODULEPATH, and load the EasyBuild module
    LINE='module use $(EB_MODULES_ROOT)'
    FILE=$(SYSTEM_BASHRC)
    MSG="Added following line to $$FILE, rerun 'source $$FILE' in your current shell session."
    grep -qF -- "$$LINE" "$$FILE" || echo "$$LINE" >> "$$FILE"
    @echo $$MSG
    @echo $$LINE

    # module use $(EB_MODULES_ROOT)
    # module load EasyBuild

# lmod & lua
.ONESHELL:
$(LMOD_EXE): $(LUA_EXE) $(MAKE_EXE)
    set -euxo pipefail
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR)
    rm -rf Lmod-$(LMOD_VERSION)*
    wget https://sourceforge.net/projects/lmod/files/Lmod-$(LMOD_VERSION).tar.bz2
    bunzip2 Lmod-$(LMOD_VERSION).tar.bz2
    tar xf Lmod-$(LMOD_VERSION).tar
    cd Lmod-$(LMOD_VERSION)
    ./configure --prefix=$(LMOD_INSTALL_PREFIX)
    sudo make install

    sudo ln -fs $(LMOD_ROOT)/init/profile $(SYSTEM_PROFILE_D)/z00_lmod.sh
    sudo ln -fs $(LMOD_ROOT)/init/cshrc $(SYSTEM_PROFILE_D)/z00_lmod.csh
    # sudo ln -s /opt/apps/lmod/lmod/init/profile.fish   /etc/fish/conf.d/z00_lmod.fish

.ONESHELL:
$(LUA_EXE): $(MAKE_EXE)
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    sudo mkdir -p $(APPS_ROOT)/lua/$(LUA_VERSION)
    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR)
    rm -rf lua-$(LUA_VERSION)*
    # https://www.lua.org/download.html
    # curl -R -O http://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz
    wget https://sourceforge.net/projects/lmod/files/lua-$(LUA_VERSION).tar.bz2
    bunzip2 lua-$(LUA_VERSION).tar.bz2
    tar xf lua-$(LUA_VERSION).tar
    cd lua-$(LUA_VERSION)
    ./configure --prefix=$(APPS_ROOT)/lua/$(LUA_VERSION)
    make
    sudo make install
    cd $(APPS_ROOT)/lua
    sudo ln -s $(LUA_VERSION) lua
    sudo mkdir -p $(SYSTEM_LOCAL_BIN)
    sudo ln -s $(LUA_EXE) $(SYSTEM_LOCAL_BIN)

# easybuild repositories
eb-repositories: $(EB_GIT_REPO_ROOT)/easybuild $(EB_GIT_REPO_ROOT)/easybuild-easyblocks $(EB_GIT_REPO_ROOT)/easybuild-easyframework $(EB_GIT_REPO_ROOT)/easybuild-easyconfigs $(EB_GIT_REPO_ROOT)/JSC

$(EB_GIT_REPO_ROOT)/easybuild:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild.git

$(EB_GIT_REPO_ROOT)/easybuild-easyblocks:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-easyblocks.git

$(EB_GIT_REPO_ROOT)/easybuild-easyframework:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-framework.git

$(EB_GIT_REPO_ROOT)/easybuild-easyconfigs:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-easyconfigs.git

.ONESHELL:
$(EB_GIT_REPO_ROOT)/JSC:
    mkdir -p $(EB_GIT_REPO_ROOT)
    cd $(EB_GIT_REPO_ROOT)
    git clone https://github.com/jotelha/JSC.git
    cd JSC
    git checkout hfr13-eb-4.2

# eb env file
eb_env.sh:
    cat <<- EOF > $@
        # export SOFTWAREROOT=$HOME/software
        export STAGE=$(EB_STAGE)

        prefix=$(EB_ROOT)
        buidlpath=$${prefix}/build
        container_path=$${prefix}/containers
        install_path=$${prefix}/easybuild
        repository_path=$${prefix}/ebfiles_repo
        sources_path=$${prefix}/sources

        # software_root=$${SOFTWAREROOT}
        stage=$${STAGE}
        # stage_path="$${software_root}/Stages/$${stage}"
        # sources_path="$${HOME}/eb/sources"

        common_eb_path="$${HOME}/git"
        common_jsc_eb_path="$${HOME}/git/JSC"
        gr_path="$${common_eb_path}/easybuild-easyconfigs/easybuild/easyconfigs"
        jsc_gr_path="$${common_jsc_eb_path}/Golden_Repo/$${stage}"
        custom_easyblocks_path="$${common_jsc_eb_path}/Custom_EasyBlocks/$${stage}"
        custom_toolchains_path="$${common_jsc_eb_path}/Custom_Toolchains/$${stage}"
        custom_mns_path="$${common_jsc_eb_path}/Custom_MNS/$${stage}"

        # export EASYBUILD_ROBOT=$${gr_path}
        export EASYBUILD_ROBOT_PATHS=$${gr_path}:$${jsc_gr_path}
        export EASYBUILD_DETECT_LOADED_MODULES=error
        export EASYBUILD_ALLOW_LOADED_MODULES=EasyBuild
        export EASYBUILD_SOURCEPATH=$${sources_path}
        export EASYBUILD_INSTALLPATH=$${install_path}
        export EASYBUILD_BUILDPATH=/dev/shm
        export EASYBUILD_INCLUDE_TOOLCHAINS="$${custom_toolchains_path}/*.py,$${custom_toolchains_path}/fft/*.py,$${custom_toolchains_path}/compiler/*.py"
        # export EASYBUILD_INCLUDE_EASYBLOCKS="$${custom_easyblocks_path}/*.py"
        export EASYBUILD_REPOSITORY=FileRepository
        export EASYBUILD_REPOSITORYPATH=$${repository_path}
        export EASYBUILD_SET_GID_BIT=1
        export EASYBUILD_MODULES_TOOL=Lmod
        export EASYBUILD_MODULE_SYNTAX=Lua
        export EASYBUILD_PREFIX=$${prefix}
        export EASYBUILD_INCLUDE_MODULE_NAMING_SCHEMES="$${custom_mns_path}/*.py"
        export EASYBUILD_MODULE_NAMING_SCHEME=FlexibleCustomHierarchicalMNS
        export EASYBUILD_FIXED_INSTALLDIR_NAMING_SCHEME=1
        export EASYBUILD_EXPERIMENTAL=1
        export EASYBUILD_MINIMAL_TOOLCHAINS=1
        export EASYBUILD_USE_EXISTING_MODULES=1
        # export EASYBUILD_TEST_REPORT_ENV_FILTER="\*PS1\*|PROMPT\*|\*LICENSE\*"
    EOF

# misc
$(MAKE_EXE):
    sudo yum install -y make

$(PYTHON_EXE):
    sudo yum install -y python3

.PHONY: list
list:
    @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: test
test:
    $(foreach var,$(.VARIABLES),$(info $(var) = $($(var))))
