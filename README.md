# CentOS 8 container playground

## EasyBuild

Generate `eb_env.sh`, `eb_jsc_env.sh` and `eb_dev_env.sh` with

    make eb_env.sh
    make eb_dev_env.sh
    make eb_jsc_env.sh

and choose between

    module load EasyBuild
    source eb_env.sh

or

    module load EasyBuild
    source eb_jsc_env.sh

or

    module load EasyBuild-devel
    source eb_ev_env.sh

## SIngularity cache

Set 

   export SINGULARITY_CACHEDIR=/mnt/dat/tmp/singularity_cachedir
   export SINGULARITY_TMPDIR=/mnt/dat/tmp/singularity_tmpdir

or some other spatious volume.

## Dependency graph

Install

    sudo pip3 install python-graph-core
    sudo pip3 install python-graph-dot
    sudo pip3 install graphviz graphviz-python

## Memory shortage

Create a swap file (here 4 GB) with

    sudo dd if=/dev/zero of=/swapfile bs=1024 count=4194304
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile   
    sudo swapon /swapfile 

and double-check with

    sudo swapon --show

