# CentOS 8 container playground

## EasyBuild

Generate `eb_env.sh` and `eb_dev_env.sh` with

    make eb_env.sh
    make eb_dev_env.sh

and choose between

    module load EasyBuild
    source eb_env.sh

or

    module load EasyBuild-devel
    source eb_ev_env.sh


## Memory shortage

Create a swap file (here 4 GB) with

    sudo dd if=/dev/zero of=/swapfile bs=1024 count=4194304
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile   
    sudo swapon /swapfile 

and double-check with

    sudo swapon --show

