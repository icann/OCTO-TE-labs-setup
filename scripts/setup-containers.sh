#!/bin/bash

set -exou

# Init script for creating/upgrading template containers

## You'll have to run this script only once, right after initiating a new cloud lab instance from scratch

## ================================================================================================"
lxc list

## ================================================================================================"
## Container creation

# Get lxc Ubuntu image
lxc image copy ubuntu:24.04 local: --alias ubuntu -q

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
# disable systemd-resolved, as it blocks port 53 for other DNS servers
lxc exec hostX -- sh -c "systemctl disable systemd-resolved"
lxc exec hostX -- sh -c "systemctl stop systemd-resolved"
lxc exec hostX -- sh -c "rm -f /etc/resolv.conf"
lxc exec hostX -- sh -c 'echo "nameserver 9.9.9.9" > /etc/resolv.conf'
# ISC bind9 repo
lxc exec hostX -- sh -c "add-apt-repository ppa:isc/bind" 
# CZ.NIC Knot repo
lxc exec hostX -- sh -c 'wget -O /usr/share/keyrings/cznic-labs-pkg.gpg https://pkg.labs.nic.cz/gpg'
lxc exec hostX -- sh -c 'echo "deb [signed-by=/usr/share/keyrings/cznic-labs-pkg.gpg] https://pkg.labs.nic.cz/knot-dns $(lsb_release -s -c) main" > /etc/apt/sources.list.d/cznic-labs-knot-dns.list'
# PowerDNS repos
lxc exec hostX -- sh -c 'curl -s https://repo.powerdns.com/FD380FBB-pub.asc > /usr/share/keyrings/auth-49-pub.asc'
lxc exec hostX -- sh -c 'curl -s https://repo.powerdns.com/FD380FBB-pub.asc > /usr/share/keyrings/rec-52-pub.asc'
lxc exec hostX -- sh -c 'curl -s https://repo.powerdns.com/FD380FBB-pub.asc > /usr/share/keyrings/dnsdist-19-pub.asc'
lxc exec hostX -- sh -c 'echo "deb [signed-by=/usr/share/keyrings/auth-49-pub.asc] http://repo.powerdns.com/ubuntu $(lsb_release -s -c)-auth-49 main" >  /etc/apt/sources.list.d/pdns.list'
lxc exec hostX -- sh -c 'echo "deb [signed-by=/usr/share/keyrings/rec-52-pub.asc] http://repo.powerdns.com/ubuntu $(lsb_release -s -c)-rec-52 main" >> /etc/apt/sources.list.d/pdns.list'
lxc exec hostX -- sh -c 'echo "deb [signed-by=/usr/share/keyrings/dnsdist-19-pub.asc] http://repo.powerdns.com/ubuntu $(lsb_release -s -c)-dnsdist-19 main" >> /etc/apt/sources.list.d/pdns.list'
lxc file push ../configs/apt/auth-49    hostX/etc/apt/preferences.d/auth-49
lxc file push ../configs/apt/rec-52     hostX/etc/apt/preferences.d/rec-52
lxc file push ../configs/apt/dnsdist-19 hostX/etc/apt/preferences.d/dnsdist-19
# Now update apt to make new repos available    
lxc exec hostX -- sh -c "apt-get -yq update"
lxc exec hostX -- sh -c "apt-get -yq --with-new-pkgs upgrade"
lxc exec hostX -- sh -c "apt-get -yq install curl gnupg nano joe bind9-dnsutils knot-dnsutils net-tools traceroute wget man openssh-server tcpdump dnstop whois telnet --no-install-recommends"
# install ICANN RDAP client
lxc exec hostX -- sh -c 'curl -s -L -O https://github.com/icann/icann-rdap/releases/latest/download/icann-rdap-x86_64-unknown-linux-gnu.tar.gz'
lxc exec hostX -- sh -c 'tar xzf icann-rdap-x86_64-unknown-linux-gnu.tar.gz rdap'
lxc exec hostX -- sh -c 'mv rdap /usr/bin'
lxc exec hostX -- sh -c 'rm -f icann-rdap-x86_64-unknown-linux-gnu.tar.gz'
# Allow password authentication for ssh, needed for webssh
lxc exec hostX -- sh -c "sed -i -e's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config"
# add webssh user sysadm and allow root access
lxc exec hostX -- sh -c 'useradd sysadm -c "Adm" -d /home/sysadm -m -G sudo -s /bin/bash'
lxc exec hostX -- sh -c 'echo "sysadm:icannws" | chpasswd'
lxc exec hostX -- sh -c 'echo "sysadm ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sysadm'
#
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
lxc stop rtrX

## ================================================================================================"
## More hostX container config
#lxc start hostX
#lxc exec hostX -- cloud-init status --wait
#lxc exec hostX -- sh -c "
#    apt-get -yq install git build-essential autoconf m4 libtool mtr-tiny ansible python3-paramiko python3-pip tree cmake librtlsdr2 librtr-dev 
#    pip3 install --break-system-packages ansible-pylibssh
#    ansible-galaxy collection install cisco.ios
#    cd
#    git clone https://github.com/bgp/bgpq4.git
#    cd bgpq4
#    sed -i 's/64496/65100/g' expander.c
#    ./bootstrap
#    ./configure
#    make
#    make install
#    make clean
#    cd
#    git clone https://github.com/rtrlib/rtrlib.git
#    cd rtrlib/
#    cmake -D CMAKE_BUILD_TYPE=Debug -D RTRLIB_TRANSPORT_SSH=No .
#    make
#    make install
#    make clean
#    apt-get -yq install librtr0
#"
#lxc exec hostX -- sh -c 'echo "PATH=\"$PATH\"" > /etc/environment'
#lxc stop hostX

## ================================================================================================"
## Server templates
lxc copy hostX unboundX
lxc copy hostX bindX
lxc copy hostX odsX
lxc copy hostX nsdX
lxc copy hostX RPKIfortX

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
lxc exec unboundX -- apt-get -yq install unbound

## ================================================================================================"
lxc exec bindX -- apt-get -yq install bind9
lxc exec bindX -- systemctl enable named
lxc exec bindX -- systemctl start named
# add user to group bind - allows for calling rndc
lxc exec bindX -- adduser sysadm bind

## ================================================================================================"
lxc exec nsdX -- apt-get install -yq nsd

## ================================================================================================"
lxc exec odsX -- sh -c "DEBIAN_FRONTEND=noninteractive apt-get -yq install opendnssec softhsm2 bind9"
lxc exec odsX -- systemctl enable named
lxc exec odsX -- systemctl start named
# add user to group bind - allows for calling rndc
lxc exec odsX -- adduser sysadm bind

## ================================================================================================"
lxc exec RPKIfortX -- sh -c "
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
lxc exec RPKIfortX -- systemctl daemon-reload
lxc exec RPKIfortX -- systemctl enable fortd
#lxc exec RPKIfortX -- systemctl status fortd

## ================================================================================================"
lxc stop unboundX bindX odsX nsdX RPKIfortX

## ================================================================================================"
# List all lxc containers
lxc list

## ================================================================================================"
echo "DONE setup-containers.sh"
