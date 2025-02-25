#!/bin/bash

set -exou

# Init script for creating/upgrading template containers

## You'll have to run this script only once, right after initiating a new cloud lab instance from scratch

## ================================================================================================"
lxc list

## ================================================================================================"
## Container creation

# Get lxc Ubuntu image
lxc image copy ubuntu:24.04 local: --alias ubuntu

## ================================================================================================"
# Create template host (hostX) using ubuntu image)
lxc init local:ubuntu hostX
lxc start hostX
lxc exec hostX -- cloud-init status --wait
lxc exec hostX -- sh -c "rm -f /etc/netplan/10-lxc.yaml"
lxc exec hostX -- sh -c 'echo "network:" > /etc/netplan/10-lxc.yaml'
lxc exec hostX -- sh -c 'echo "   version: 2" >> /etc/netplan/10-lxc.yaml'
lxc exec hostX -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
lxc stop hostX
lxc start hostX
lxc exec hostX -- cloud-init status --wait
lxc exec hostX -- sh -c "rm -f /etc/resolv.conf"
lxc exec hostX -- sh -c 'echo "nameserver 9.9.9.9" > /etc/resolv.conf'
lxc exec hostX -- sh -c "systemctl disable systemd-resolved"
lxc exec hostX -- sh -c "systemctl stop systemd-resolved"
lxc stop hostX
lxc start hostX
lxc exec hostX -- cloud-init status --wait
lxc exec hostX -- sh -c "apt-get -yq update"
lxc exec hostX -- sh -c "apt-get -yq upgrade"
lxc exec hostX -- sh -c "apt-get -yq install curl gnupg nano joe dnsutils net-tools traceroute wget man openssh-server tcpdump dnstop --no-install-recommends"
lxc exec hostX -- sh -c "sed -i -e's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config"
lxc stop hostX

## ================================================================================================"
## Create router (rtrX) master (copy from hostX)
lxc copy hostX rtrX
lxc start rtrX
lxc exec rtrX -- cloud-init status --wait
lxc exec rtrX -- sh -c "curl -s https://deb.frrouting.org/frr/keys.asc | sudo tee /etc/apt/trusted.gpg.d/frr.asc"
lxc exec rtrX -- sh -c 'echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | tee -a /etc/apt/sources.list.d/frr.list'
lxc exec rtrX -- sh -c "apt-get -yq update"
lxc exec rtrX -- sh -c "apt-get -yq install frr frr-pythontools frr-rpki-rtrlib"
lxc file push ../configs/frr/etc/frr/daemons.cfg rtrX/etc/frr/daemons
lxc exec rtrX -- sh -c 'chown frr:frr /etc/frr/daemons'
lxc exec rtrX -- sh -c 'chmod 755 /etc/frr'
lxc exec rtrX -- sh -c 'chmod 755 /var/run/frr'
lxc exec rtrX -- sh -c 'chmod 644 /etc/frr/vtysh.conf'
lxc exec rtrX -- sh -c 'useradd rtradm -c "Adm" -g frrvty -d /home/rtradm -m -s /usr/bin/vtysh'
lxc exec rtrX -- sh -c 'echo "rtradm:icannws" | chpasswd'
lxc exec rtrX -- sh -c 'useradd sysadm -c "Adm" -d /home/sysadm -m -G sudo -s /bin/bash'
lxc exec rtrX -- sh -c 'echo "sysadm:icannws" | chpasswd'
lxc exec rtrX -- sh -c 'echo "sysadm ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sysadm'
lxc stop rtrX

## ================================================================================================"
## More hostX container config
lxc start hostX
lxc exec hostX -- cloud-init status --wait
lxc exec hostX -- sh -c 'useradd sysadm -c "Adm" -d /home/sysadm -m -G sudo -s /bin/bash'
lxc exec hostX -- sh -c 'echo "sysadm:icannws" | chpasswd'
lxc exec hostX -- sh -c 'echo "sysadm ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sysadm'
lxc exec hostX -- sh -c "
    apt-get -yq install git build-essential autoconf m4 libtool mtr-tiny whois telnet ansible python3-paramiko python3-pip tree cmake librtlsdr2 librtr-dev 
    pip3 install --break-system-packages ansible-pylibssh
    ansible-galaxy collection install cisco.ios
    cd
    git clone https://github.com/bgp/bgpq4.git
    cd bgpq4
    sed -i 's/64496/65100/g' expander.c
    ./bootstrap
    ./configure
    make
    make install
    make clean
    cd
    git clone https://github.com/rtrlib/rtrlib.git
    cd rtrlib/
    cmake -D CMAKE_BUILD_TYPE=Debug -D RTRLIB_TRANSPORT_SSH=No .
    make
    make install
    make clean
    apt-get -yq install librtr0
    curl -L -O https://github.com/icann/icann-rdap/releases/latest/download/icann-rdap-x86_64-unknown-linux-gnu.tar.gz
    tar xzf icann-rdap-x86_64-unknown-linux-gnu.tar.gz rdap
    mv rdap /usr/bin
"
lxc exec hostX -- sh -c 'echo "PATH=\"$PATH\"" > /etc/environment'
lxc stop hostX
echo " "

## ================================================================================================"
## Server templates
lxc copy rtrX srvX
lxc copy srvX unboundX
lxc copy srvX bindX
lxc copy srvX odsX
lxc copy srvX nsdX
lxc copy srvX RPKIfortX

lxc start unboundX
lxc start bindX
lxc start odsX
lxc start nsdX
lxc start RPKIfortX

lxc exec unboundX -- cloud-init status --wait
lxc exec bindX -- cloud-init status --wait
lxc exec odsX -- cloud-init status --wait
lxc exec nsdX -- cloud-init status --wait
lxc exec RPKIfortX -- cloud-init status --wait


## ================================================================================================"
lxc exec unboundX -- apt-get -yq install unbound --no-install-recommends

## ================================================================================================"
lxc exec bindX -- sh -c "
    # install latest stable bind9
    add-apt-repository ppa:isc/bind
    apt-get -yq update
    apt-get -yq install bind9
"

## ================================================================================================"
lxc exec nsdX -- apt-get install -yq nsd

## ================================================================================================"
lxc exec odsX -- sh -c "
    export DEBIAN_FRONTEND=noninteractive
    # install latest stable bind9
    add-apt-repository ppa:isc/bind
    apt-get -yq update
    apt-get -yq install opendnssec softhsm2 bind9
"

## ================================================================================================"
lxc exec RPKIfortX -- sh -c "
    systemctl stop frr
    systemctl disable frr
    apt-get -yq remove frr frr-pythontools
    apt-get -yq autoremove
    rm -Rf /etc/frr/
    apt-get -yq update
    apt-get -yq --no-install-recommends install \
        autoconf automake build-essential git libjansson-dev \
        libssl-dev pkg-config rsync ca-certificates curl \
        libcurl4-openssl-dev libxml2-dev \
        less vim
    git clone https://github.com/NICMx/FORT-validator.git
    cd FORT-validator
    sed -i 's/AC_PREREQ(\[2.71\])/AC_PREREQ(\[2.60\])/g' configure.ac
    ./autogen.sh
    ./configure
    make
    make install
    make clean
    mkdir -p /etc/fort
    mkdir -p /var/fort/tal
    mkdir -p /var/fort/repository
    printf 'yes\n' | fort --init-tals --tal /var/fort/tal
    "
lxc file push ../configs/RPKI_fort/etc/fort/config.json RPKIfortX/etc/fort/config.json
lxc file push ../configs/RPKI_fort/lib/systemd/system/fortd.service.cfg RPKIfortX/lib/systemd/system/fortd.service
lxc exec RPKIfortX -- sh -c "
    systemctl daemon-reload
    systemctl enable fortd
    #systemctl status fortd
"

## ================================================================================================"
lxc stop unboundX bindX odsX nsdX RPKIfortX

## ================================================================================================"
# List all lxc containers
lxc list

## ================================================================================================"
echo "===> End of all generate-container-templates.sh tasks !!!"
