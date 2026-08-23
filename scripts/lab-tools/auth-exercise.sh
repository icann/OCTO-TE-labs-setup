#!/bin/bash
#
# Exercise authoritative DNS server management
#
# Container:
#   auth-exercise
#
# Role:
#   auth-exercise
#
# Addresses:
#   100.64.0.55  internal.
#   100.64.0.56  badnsname.internal.
#   100.64.0.57  evilnsip.internal.
#
# RPZ is temporarily hosted here during Stage 1.
# It will move to auth-rpz during Stage 3.
#

create_auth_exercise () {
    echo "Create auth-exercise"

    lxc copy hostX auth-exercise
    lxc start auth-exercise
    lxc exec auth-exercise -- cloud-init status --wait

    #
    # Network
    #
    lxc config device add auth-exercise eth0 nic \
        name=eth0 \
        nictype=bridged \
        parent=net-bb

    sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-auth-exercise.yaml \
        > $workdir/bb-auth-exercise.yaml

    lxc file push \
        $workdir/bb-auth-exercise.yaml \
        auth-exercise/etc/netplan/bb-lxc.yaml

    lxc exec auth-exercise -- sh -c \
        'chmod 600 /etc/netplan/bb-lxc.yaml'

    #
    # Host identity
    #
    lxc exec auth-exercise -- sh -c \
        'echo auth-exercise >/etc/hostname'

    lxc exec auth-exercise -- sh -c \
        'hostname auth-exercise'

    lxc exec auth-exercise -- sh -c \
        'echo 127.0.0.222 auth-exercise >>/etc/hosts'

    lxc exec auth-exercise -- sh -c \
        'netplan apply'

    #
    # Install authoritative DNS server
    #
    lxc exec auth-exercise -- sh -c \
        'apt install -qy bind9'

    #
    # Generate BIND configuration
    #
    sed -e "s|%IPv6pfx%|${IPv6prefix}|g" \
        ../configs/auth-exercise/named.conf \
        > $workdir/auth-exercise-named.conf

    lxc file push \
        $workdir/auth-exercise-named.conf \
        auth-exercise/etc/bind/named.conf

    lxc exec auth-exercise -- sh -c \
        'chown -R bind:bind /etc/bind/*'

    #
    # Create zone directory
    #
    lxc exec auth-exercise -- sh -c \
        'mkdir -p /var/lib/bind/zones'

    #
    # Push exercise zones
    #
    lxc file push \
        ../configs/auth-exercise/db.internal \
        auth-exercise/var/lib/bind/zones/db.internal

    lxc file push \
        ../configs/auth-exercise/db.badnsname.internal \
        auth-exercise/var/lib/bind/zones/db.badnsname.internal

    lxc file push \
        ../configs/auth-exercise/db.evilnsip.internal \
        auth-exercise/var/lib/bind/zones/db.evilnsip.internal

    #
    # Temporary RPZ placement.
    # This zone will move to auth-rpz during Stage 3.
    #
    lxc file push \
        ../configs/auth-exercise/db.rpz \
        auth-exercise/var/lib/bind/zones/db.rpz

    lxc exec auth-exercise -- sh -c \
        'chown -R bind:bind /var/lib/bind'

    #
    # Validate BIND configuration and zones
    #
    lxc exec auth-exercise -- \
        named-checkconf /etc/bind/named.conf

    lxc exec auth-exercise -- \
        named-checkzone internal \
        /var/lib/bind/zones/db.internal

    lxc exec auth-exercise -- \
        named-checkzone badnsname.internal \
        /var/lib/bind/zones/db.badnsname.internal

    lxc exec auth-exercise -- \
        named-checkzone evilnsip.internal \
        /var/lib/bind/zones/db.evilnsip.internal

    lxc exec auth-exercise -- \
        named-checkzone rpz \
        /var/lib/bind/zones/db.rpz

    #
    # Restart container so BIND starts with final configuration
    #
    lxc stop auth-exercise
    lxc start auth-exercise
    lxc exec auth-exercise -- cloud-init status --wait

    echo "Done - Create auth-exercise"
}


delete_auth_exercise () {
    echo "Delete auth-exercise"
    lxc delete auth-exercise
    echo "Done - Delete auth-exercise"
}


start_auth_exercise () {
    echo "Start - auth-exercise"
    lxc start auth-exercise
    lxc exec auth-exercise -- cloud-init status --wait
    echo "Done - Start auth-exercise"
}


stop_auth_exercise () {
    echo "Stop auth-exercise"
    lxc stop -f auth-exercise
    echo "Done - Stop auth-exercise"
}
