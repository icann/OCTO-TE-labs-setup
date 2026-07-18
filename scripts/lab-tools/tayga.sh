#!/bin/bash

#
# Install NAT64 on the host system
# (needs to be on the host, will *NOT* work in a container)
#

create_nat64 () {
    echo "Create NAT64"

    sudo apt install -qy tayga

    cat <<EOF | sudo tee /etc/tayga.conf
tun-device nat64
ipv4-addr 192.0.2.1
ipv6-addr fd00:1234:5678::1
dynamic-pool 192.0.2.0/24
prefix 64:ff9b::/96
data-dir /var/lib/tayga
EOF

    sudo tayga --config /etc/tayga.conf --mktun
    sudo ip link set nat64 up
    sudo ip route add 192.0.2.0/24 dev nat64
    sudo ip -6 route add 64:ff9b::/96 dev nat64
    sudo systemctl restart tayga
    sudo /usr/lib/systemd/systemd-sysv-install enable tayga

    #
    echo "Done - Create NAT64"
}

stop_nat64() {
    echo "Stop NAT64"
    sudo systemctl stop tayga
    sudo /usr/lib/systemd/systemd-sysv-install disable tayga
    sudo tayga --config /etc/tayga.conf --rmmod
    sudo ip link del nat64
    sudo ip route del 192.0.2.0/24 dev nat64
    sudo ip -6 route del 64:ff9b::/96 dev nat64
    #
    echo "Done - Stop NAT64"
}