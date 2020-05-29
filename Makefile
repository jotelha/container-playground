.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

.PHONY: install-podman
install-podman: /usr/bin/podman

/usr/bin/podman: /usr/bin/make
    bash install_podman.sh

.PHONY: install-singularity
install-singularity: /usr/local/bin/singularity

/usr/local/bin/singularity: /usr/bin/make
    bash install_singularity.sh

.PHONY: install-docker
install-docker: /usr/bin/docker

/usr/bin/docker: /usr/bin/make
    bash install_docker.sh

.PHONY: install-eb
install-eb: $${HOME}/.local/easybuild

$${HOME}/.local/easybuild: /opt/apps/lmod/lmod /usr/bin/python3
    bash install_eb.sh

.PHONY: install-lmod
install-lmod: /opt/apps/lmod/lmod

/opt/apps/lmod/lmod: /opt/apps/lua/lua /usr/bin/make
    bash install_lmod.sh

/opt/apps/lua/lua: /usr/bin/make
    bash install_lua.sh

/usr/bin/make:
    sudo yum install -y make

/usr/bin/python3:
    sudo yum install -y python3

.PHONY: list
list:
    @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
