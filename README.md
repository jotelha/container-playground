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

## Singularity cache

Set 

   export SINGULARITY_CACHEDIR=/mnt/dat/tmp/singularity_cachedir
   export SINGULARITY_TMPDIR=/mnt/dat/tmp/singularity_tmpdir

or some other spatious volume.

Generate `singularity_env.sh` with 

    make singularity_env.sh


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

To make swapfile permanent across reboots, add to `/etc/fstab`

    /swapfile swap swap defaults 0 0

# EasyConfig issues

UCX-1.8.0-GCCcore-9.3.0.eb has OS dependency resolved by

    sudo yum install -y libibverbs-devel

on CentOS 8.

# VPNC on CentOS 8

```bash
sudo yum install libgcrypt-devel
sudo yum install perl-core

VERSION=0.5.3
wget https://www.unix-ag.uni-kl.de/~massar/vpnc/vpnc-${VERSION}.tar.gz
tar xf vpnc-${VERSION}.tar.gz 
cd vpnc-${VERSION}
```

Now, edit `Makefile` and uncomment lines 51-52

```
OPENSSL_GPL_VIOLATION = -DOPENSSL_GPL_VIOLATION
OPENSSLLIBS = -lcrypto
```

and do

```bash
make
sudo make install
```

Create `/etc/vpnc/custom-vpnc-script` with some content like

```
#!/usr/bin/env bash

# Set up split tunneling
CISCO_SPLIT_INC=1
CISCO_SPLIT_INC_0_ADDR=10.0.0.0
CISCO_SPLIT_INC_0_MASK=255.0.0.0
CISCO_SPLIT_INC_0_MASKLEN=8
CISCO_SPLIT_INC_0_PROTOCOL=0
CISCO_SPLIT_INC_0_SPORT=0
CISCO_SPLIT_INC_0_DPORT=0

# Call regular vpnc-script
. /etc/vpnc/vpnc-script
```

(from https://blog.scottlowe.org/2019/03/12/split-tunneling-with-vpnc)

and modify `/etc/vpnc/defaults.cong`, adding the last line

```
Script /etc/vpnc/custom-vpnc-script
```

for split tunnelling.

Create a systemd unit file `/etc/systemd/system/vpnc@.service` with content

```
[Unit]                                                                                                                                                                       
Description=VPNC connection to %i
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=forking
ExecStart=/usr/local/sbin/vpnc --pid-file=/run/vpnc@%i.pid /etc/vpnc/%i.conf
PIDFile=/run/vpnc@%i.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

pick a connection name `some-vpn-connection`,
create some configuration file `/etc/vpnc/some-vpn-connection.conf` and bring up
according service with

```bash
sudo systemctl enable vpnc@some-vpn-connection
sudo systemctl start vpnc@some-vpn-connection
```

Inspect log messages with

    journalctl _SYSTEMD_UNIT=vpnc@some-vpn-connection.service
