.RECIPEPREFIX := $(.RECIPEPREFIX) 
SHELL := /bin/bash

.PHONY: install-podman
    bash install_podman.sh

.PHONY: install-singularity
install-singularity: install-basics
    bash install_singularity.sh

.PHONY: install-docker
install-docker: install-basics
    bash install_docker.sh

.PHONY: install-basics
install-basics:
    sudo apt-get update
    sudo apt-get -y install python3-venv

