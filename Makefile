.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

DEVEL_MODULE_DIR=$${HOME}/.local/easybuild/modules/all/Devel
DEVEL_MODULE_FILE=$(DEVEL_MODULE_DIR)/InstallSoftware.lua
DOCKER_EXE=/usr/bin/docker
EB_DIR=$${HOME}/.local/easybuild
LMOD_DIR=/opt/apps/lmod/lmod
LUA_DIR=/opt/apps/lua/lua
MAKE_EXE=/usr/bin/make
PODMAN_EXE=/usr/bin/podman
PYTHON_EXE=/usr/bin/python3
SINGULARITY_EXE=/usr/local/bin/singularity

.PHONY: install-docker
install-docker: $(DOCKER_EXE)

.PHONY: install-podman
install-podman: $(PODMAN_EXE)

.PHONY: install-singularity
install-singularity: $(SINGULARITY_EXE)

.PHONY: install-devel-mod
install-devel-mod: $(DEVEL_MODULE_FILE)

.PHONY: install-eb
install-eb: $(EB_DIR)

.PHONY: install-lmod
install-lmod: $(LMOD_DIR)

$(PODMAN_EXE): /usr/bin/make
    bash install_podman.sh

$(SINGULARITY_EXE): $(MAKE_EXE)
    bash install_singularity.sh

$(DOCKER_EXE): $(MAKE_EXE)
    bash install_docker.sh

$(DEVEL_MODULE_FILE): $(EB_DIR)
    mkdir -p $(DEVEL_MODULE_DIR)
    cp eb/InstallSoftware.lua $(DEVEL_MODULE_FILE)

$(EB_DIR): $(LMOD_DIR) $(PYTHON_EXE)
    bash install_eb.sh

$(LMOD_DIR): $(LUA_DIR) $(MAKE_EXE)
    bash install_lmod.sh

$(LUA_DIR): $(MAKE_EXE)
    bash install_lua.sh

$(MAKE_EXE):
    sudo yum install -y make

$(PYTHON_EXE):
    sudo yum install -y python3

.PHONY: list
list:
    @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
