#!/bin/bash

#
# Install NAT64 on the host system
# (needs to be on the host, will *NOT* work in a container)
#

create_nat64 () {
    echo "Create NAT64"

    cat <<EOF | sudo tee /etc/tayga.conf
tun-device nat64
ipv4-addr 192.0.2.1
ipv6-addr fd00:1234:5678::1
dynamic-pool 192.0.2.0/24
prefix 64:ff9b::/96
data-dir /var/lib/tayga
EOF

    tayga --config /etc/tayga.conf --mktun
    ip link set nat64 up
    ip route add 192.0.2.0/24 dev nat64
    ip -6 route add 64:ff9b::/96 dev nat64
    systemctl restart tayga
    /usr/lib/systemd/systemd-sysv-install enable tayga

    #
    echo "Done - Create NAT64"
}

stop_nat64() {
    echo "Stop NAT64"
    if systemctl is-active --quiet tayga.service; then
        systemctl stop tayga.service
        /usr/lib/systemd/systemd-sysv-install disable tayga
    fi
    ip route del 192.0.2.0/24 dev nat64 2>/dev/null || true
    ip -6 route del 64:ff9b::/96 dev nat64 2>/dev/null || true
    ip link del nat64 2>/dev/null || true
    #
    echo "Done - Stop NAT64"
}