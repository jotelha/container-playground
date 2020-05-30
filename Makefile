.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

# general
PREFIX := /mnt/dat
APPS_ROOT := $(PREFIX)/opt/apps
SOURCES_DIR := $(PREFIX)/src

# OS-specific
PKG_MGR=apt-get
VERSION_ID=20.04
SYSTEM_PROFILE_D := /etc/profile.d
# system-dependent fixed
SYSTEM_BIN := /usr/bin
# system-dependent fixed
SYSTEM_LOCAL := /usr/local
SYSTEM_LOCAL_BIN := $(SYSTEM_LOCAL)/bin
# system-dependent fixed
SYSTEM_BASHRC := /etc/bash.bashrc
SYSTEM_BASH_PROFILE := /etc/profile

MAKE_EXE := $(SYSTEM_BIN)/make
# system-dependent fixed
PYTHON_EXE := $(SYSTEM_BIN)/python3
# system-dependent fixed

# Lua-realted
LUA_VERSION := 5.1.4.9
LUA_SRC := $(SOURCES_DIR)/lua-$(LUA_VERSION).tar
LUA_ROOT := $(APPS_ROOT)/lua/lua
# fixed
LUA_EXE := $(LUA_ROOT)/bin/lua
# fixed
LUAC_EXE := $(LUA_ROOT)/bin/luac
# fixed

# Lmod-related
LMOD_VERSION := 8.2
LMOD_SRC := $(SOURCES_DIR)/Lmod-$(LMOD_VERSION).tar
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
GO_OS := linux
GO_ARCH := amd64
GO_SRC := $(SOURCES_DIR)/go$(GO_VERSION).$(GO_OS)-$(GO_ARCH).tar.gz
GO_ROOT := $(SYSTEM_LOCAL)/go
GO_EXE := $(GO_ROOT)/bin/go

# Singularity-related
SINGULARITY_VERSION := 3.5.2
SINGULARITY_SRC := $(SOURCES_DIR)/singularity-$(SINGULARITY_VERSION).tar.gz
SINGULARITY_EXE := $(SYSTEM_LOCAL_BIN)/singularity

install-all: install-docker install-podman install-singularity install-eb
    touch install-all

install-docker: $(DOCKER_EXE)
    touch install-docker

install-podman: $(PODMAN_EXE)
    touch install-podman

install-singularity: $(SINGULARITY_EXE)
    touch install-singularity

# .PHONY: install-devel-mod
# install-devel-mod: $(DEVEL_MODULE_FILE)

configure-eb: install-eb eb_env.sh eb-repositories
    touch configure-eb

install-eb: $(EB_EXE)
    touch install-eb

install-lmod: $(LMOD_EXE)
    touch install-lmod

install-lua: $(LUA_EXE)
    touch install-lua

# podman
$(PODMAN_EXE): $(MAKE_EXE)
    sudo sh -c "echo 'deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$(VERSION_ID)/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
    curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_$(VERSION_ID)/Release.key | sudo apt-key add -
    sudo apt-get update -qq
    sudo apt-get -qq -y install podman

# go & singularity
.ONESHELL:
$(GO_EXE): $(GO_SRC)
    # actually, no sources, just binary package
    # https://golang.org/dl/
    sudo tar -C $(SYSTEM_LOCAL) -xzvf $(GO_SRC) # Extracts the archive
    LINE='export PATH="$(GO_ROOT)/bin:$$PATH"'
    FILE=$(SYSTEM_BASHRC)
    MSG="Added following line to $$FILE, rerun 'source $$FILE' in your current shell session."
    grep -qF -- "$$LINE" "$$FILE" || echo "$$LINE" | sudo tee -a "$$FILE"
    @echo $$MSG
    @echo $$LINE

$(GO_SRC):
    mkdir -p $(SOURCES_DIR)
    wget -O $@ https://dl.google.com/go/go$(GO_VERSION).$(GO_OS)-$(GO_ARCH).tar.gz  # Downloads the required Go package


$(SINGULARITY_EXE): $(SINGULARITY_SRC) $(GO_EXE) $(MAKE_EXE)
    # https://sylabs.io/guides/3.5/user-guide/quick_start.html#quick-installation-steps
    # accessed 2020/05/18
    sudo $(PKG_MGR) install -y \
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

    -rm -rf $(SOURCES_DIR)/singurlarity
    cd $(SOURCES_DIR) && tar -xzf singularity-$(SINGULARITY_VERSION).tar.gz
    source $(SYSTEM_BASH_PROFILE) && cd $(SOURCES_DIR)/singularity && ./mconfig && make -C builddir && sudo make -C builddir install

$(SINGULARITY_SRC):
    mkdir -p $(SOURCES_DIR)
    # -cd $(SOURCES_DIR) && rm singularity-$(SINGULARITY_VERSION).tar.gz
    wget -O $@ https://github.com/sylabs/singularity/releases/download/v$(SINGULARITY_VERSION)/singularity-$(SINGULARITY_VERSION).tar.gz

# docker
.ONESHELL:
$(DOCKER_EXE): $(MAKE_EXE)
    # https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    # accessed: 2020/05/18
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get update
    sudo apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo apt-key fingerprint 0EBFCD88

    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       eoan \
       stable"

    # sudo add-apt-repository \
    #   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    #   $(lsb_release -cs) \
    #   stable"

    sudo apt-get update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io

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
    # https://easybuild.readthedocs.io/en/latest/Installation.html
    mkdir -p $(SOURCES_DIR)
    cd $(SOURCES_DIR) && curl -O https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
    source $(SYSTEM_BASH_PROFILE) && cd $(SOURCES_DIR) && python3 bootstrap_eb.py $(EB_ROOT)
    # update $MODULEPATH, and load the EasyBuild module
    LINE='module use $(EB_MODULES_ROOT)'
    FILE=$(SYSTEM_BASH_PROFILE)
    MSG="Added following line to $$FILE, rerun 'source $$FILE' in your current shell session."
    grep -qF -- "$$LINE" "$$FILE" || echo "$$LINE" | sudo tee -a "$$FILE"
    @echo $$MSG
    @echo $$LINE

# lmod & lua
$(LMOD_EXE): $(LMOD_SRC) $(LUA_EXE) $(MAKE_EXE)
    # set -euxo pipefail
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    sudo $(PKG_MGR) install tcl-dev
    -rm -rf $(SOURCES_DIR)/Lmod-$(LMOD_VERSION)
    cd $(SOURCES_DIR) && tar xf Lmod-$(LMOD_VERSION).tar
    cd $(SOURCES_DIR)/Lmod-$(LMOD_VERSION) && ./configure --prefix=$(LMOD_INSTALL_PREFIX) && make install
    sudo ln -fs $(LMOD_ROOT)/init/profile $(SYSTEM_PROFILE_D)/z00_lmod.sh
    sudo ln -fs $(LMOD_ROOT)/init/cshrc $(SYSTEM_PROFILE_D)/z00_lmod.csh
    # sudo ln -s /opt/apps/lmod/lmod/init/profile.fish   /etc/fish/conf.d/z00_lmod.fish

$(LMOD_SRC):
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    mkdir -p $(SOURCES_DIR)
    -rm $@.bz2
    -rm $@
    wget -O $@.bz2 https://sourceforge.net/projects/lmod/files/Lmod-$(LMOD_VERSION).tar.bz2/download?use_mirror=netix
    bunzip2 -c $@.bz2 > $@

$(LUA_EXE): $(LUA_SRC) $(MAKE_EXE)
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    -rm -rf  $(SOURCES_DIR)/lua-$(LUA_VERSION)
    # https://www.lua.org/download.html
    cd $(SOURCES_DIR) && tar xf lua-$(LUA_VERSION).tar
    mkdir -p $(APPS_ROOT)/lua/$(LUA_VERSION)
    cd $(SOURCES_DIR)/lua-$(LUA_VERSION) && ./configure --prefix=$(APPS_ROOT)/lua/$(LUA_VERSION) && make && make install
    cd $(APPS_ROOT)/lua && ln -fs $(LUA_VERSION) lua
    sudo mkdir -p $(SYSTEM_LOCAL_BIN)
    sudo ln -fs $(LUA_EXE) $(SYSTEM_LOCAL_BIN)/lua
    sudo ln -fs $(LUAC_EXE) $(SYSTEM_LOCAL_BIN)/luac

$(LUA_SRC):
    # https://lmod.readthedocs.io/en/latest/030_installing.html
    # https://www.lua.org/download.html
    mkdir -p $(SOURCES_DIR)
    -rm $@.bz2
    -rm $@
    wget -O $@.bz2 https://sourceforge.net/projects/lmod/files/lua-$(LUA_VERSION).tar.bz2/download?use_mirror=netix
    bunzip2 -c $@.bz2 > $@

# easybuild repositories
eb-repositories: | $(EB_GIT_REPO_ROOT)/easybuild $(EB_GIT_REPO_ROOT)/easybuild-easyblocks $(EB_GIT_REPO_ROOT)/easybuild-framework $(EB_GIT_REPO_ROOT)/easybuild-easyconfigs $(EB_GIT_REPO_ROOT)/JSC
    touch eb-repositories

$(EB_GIT_REPO_ROOT)/easybuild:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild.git

$(EB_GIT_REPO_ROOT)/easybuild-easyblocks:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-easyblocks.git

$(EB_GIT_REPO_ROOT)/easybuild-framework:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-framework.git

$(EB_GIT_REPO_ROOT)/easybuild-easyconfigs:
    mkdir -p $(EB_GIT_REPO_ROOT) && cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/easybuilders/easybuild-easyconfigs.git

$(EB_GIT_REPO_ROOT)/JSC:
    mkdir -p $(EB_GIT_REPO_ROOT)
    cd $(EB_GIT_REPO_ROOT) && git clone https://github.com/jotelha/JSC.git && cd JSC && git checkout hfr13-eb-4.2

# eb env file
eb_env.sh:
    cat <<- EOF > $@
        # export SOFTWAREROOT=$HOME/software
        export STAGE=$(EB_STAGE)

        prefix=$(EB_ROOT)
        build_path=\$${prefix}/build
        container_path=\$${prefix}/containers
        install_path=\$${prefix}/easybuild
        repository_path=\$${prefix}/ebfiles_repo
        sources_path=\$${prefix}/sources

        stage=\$${STAGE}
        # software_root=\$${SOFTWAREROOT}
        # stage_path="\$${software_root}/Stages/\$${stage}"

        common_eb_path="$(EB_GIT_REPO_ROOT)"
        common_jsc_eb_path="$(EB_GIT_REPO_ROOT)/JSC"
        gr_path="\$${common_eb_path}/easybuild-easyconfigs/easybuild/easyconfigs"
        jsc_gr_path="\$${common_jsc_eb_path}/Golden_Repo/\$${stage}"
        custom_easyblocks_path="\$${common_jsc_eb_path}/Custom_EasyBlocks/\$${stage}"
        custom_toolchains_path="\$${common_jsc_eb_path}/Custom_Toolchains/\$${stage}"
        custom_mns_path="\$${common_jsc_eb_path}/Custom_MNS/\$${stage}"

        # export EASYBUILD_ROBOT=\$${gr_path}
        export EASYBUILD_ROBOT_PATHS=\$${gr_path}:\$${jsc_gr_path}
        export EASYBUILD_DETECT_LOADED_MODULES=error
        export EASYBUILD_ALLOW_LOADED_MODULES=EasyBuild
        export EASYBUILD_SOURCEPATH=\$${sources_path}
        export EASYBUILD_INSTALLPATH=\$${install_path}
        export EASYBUILD_BUILDPATH=\$${build_path}
        export EASYBUILD_INCLUDE_TOOLCHAINS="\$${custom_toolchains_path}/*.py,\$${custom_toolchains_path}/fft/*.py,\$${custom_toolchains_path}/compiler/*.py"
        # export EASYBUILD_INCLUDE_EASYBLOCKS="\$${custom_easyblocks_path}/*.py"
        export EASYBUILD_REPOSITORY=FileRepository
        export EASYBUILD_REPOSITORYPATH=\$${repository_path}
        export EASYBUILD_SET_GID_BIT=1
        export EASYBUILD_MODULES_TOOL=Lmod
        export EASYBUILD_MODULE_SYNTAX=Lua
        export EASYBUILD_PREFIX=\$${prefix}
        export EASYBUILD_INCLUDE_MODULE_NAMING_SCHEMES="\$${custom_mns_path}/*.py"
        export EASYBUILD_MODULE_NAMING_SCHEME=FlexibleCustomHierarchicalMNS
        export EASYBUILD_FIXED_INSTALLDIR_NAMING_SCHEME=1
        export EASYBUILD_EXPERIMENTAL=1
        export EASYBUILD_MINIMAL_TOOLCHAINS=1
        export EASYBUILD_USE_EXISTING_MODULES=1
        # export EASYBUILD_TEST_REPORT_ENV_FILTER="\*PS1\*|PROMPT\*|\*LICENSE\*"
    EOF

# misc
$(MAKE_EXE):
    sudo $(PKG_MGR) install -y make

$(PYTHON_EXE):
    sudo $(PKG_MGR) install -y python3

.PHONY: list
list:
    @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: test
test:
    $(foreach var,$(.VARIABLES),$(info $(var) = $($(var))))
