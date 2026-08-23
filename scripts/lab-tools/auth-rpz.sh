#!/bin/bash
#
# RPZ authoritative DNS server management
#
# Container:
#   auth-rpz
#
# Role:
#   Authoritative server for the rpz. policy zone
#
# Addresses:
#   100.64.0.58
#   %IPv6pfx%:0::58
#

create_auth_rpz () {
    echo "Create auth-rpz"

    lxc copy hostX auth-rpz
    lxc start auth-rpz
    lxc exec auth-rpz -- cloud-init status --wait

    #
    # Network
    #
    lxc config device add auth-rpz eth0 nic \
        name=eth0 \
        nictype=bridged \
        parent=net-bb

    sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-auth-rpz.yaml \
        > $workdir/bb-auth-rpz.yaml

    lxc file push \
        $workdir/bb-auth-rpz.yaml \
        auth-rpz/etc/netplan/bb-lxc.yaml

    lxc exec auth-rpz -- sh -c \
        'chmod 600 /etc/netplan/bb-lxc.yaml'

    #
    # Host identity
    #
    lxc exec auth-rpz -- sh -c \
        'echo auth-rpz >/etc/hostname'

    lxc exec auth-rpz -- sh -c \
        'hostname auth-rpz'

    lxc exec auth-rpz -- sh -c \
        'echo 127.0.0.222 auth-rpz >>/etc/hosts'

    lxc exec auth-rpz -- sh -c \
        'netplan apply'

    #
    # Install authoritative DNS server
    #
    lxc exec auth-rpz -- sh -c \
        'apt install -qy bind9'

    #
    # Generate BIND configuration
    #
    sed -e "s|%IPv6pfx%|${IPv6prefix}|g" \
        ../configs/auth-rpz/named.conf \
        > $workdir/auth-rpz-named.conf

    lxc file push \
        $workdir/auth-rpz-named.conf \
        auth-rpz/etc/bind/named.conf

    #
    # Create zone directory
    #
    lxc exec auth-rpz -- sh -c \
        'mkdir -p /var/lib/bind/zones'

    #
    # Generate RPZ zone
    #
    sed -e "s|%IPv6pfx%|${IPv6prefix}|g" \
        ../configs/auth-rpz/db.rpz \
        > $workdir/db.rpz

    lxc file push \
        $workdir/db.rpz \
        auth-rpz/var/lib/bind/zones/db.rpz

    lxc exec auth-rpz -- sh -c \
        'chown -R bind:bind /etc/bind /var/lib/bind'

    #
    # Validate BIND configuration and zone
    #
    lxc exec auth-rpz -- \
        named-checkconf /etc/bind/named.conf

    lxc exec auth-rpz -- \
        named-checkzone rpz \
        /var/lib/bind/zones/db.rpz

    #
    # Restart container so BIND starts with final configuration
    #
    lxc stop auth-rpz
    lxc start auth-rpz
    lxc exec auth-rpz -- cloud-init status --wait

    echo "Done - Create auth-rpz"
}


delete_auth_rpz () {
    echo "Delete auth-rpz"
    lxc delete auth-rpz
    echo "Done - Delete auth-rpz"
}


start_auth_rpz () {
    echo "Start - auth-rpz"
    lxc start auth-rpz
    lxc exec auth-rpz -- cloud-init status --wait
    echo "Done - Start auth-rpz"
}


stop_auth_rpz () {
    echo "Stop auth-rpz"
    lxc stop -f auth-rpz
    echo "Done - Stop auth-rpz"
}
