.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

.PHONY: install-podman
install-podman: install-basics
    bash install_podman.sh

.PHONY: install-singularity
install-singularity: install-basics
    bash install_singularity.sh

.PHONY: install-docker
install-docker: install-basics
    bash install_docker.sh

.PHONY: install-basics
install-basics:
    sudo yum install -y git make

.PHONY: list
list:
    @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
