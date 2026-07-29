#!/bin/bash

create_networks () {
    echo "Creating all networks..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc network create grp${grp}-lan ipv6.address=none ipv4.address=none ipv4.nat=false
        lxc network create grp${grp}-int ipv6.address=none ipv4.address=none ipv4.nat=false
        lxc network create grp${grp}-dmz ipv6.address=none ipv4.address=none ipv4.nat=false
        lxc network create grp${grp}-extra ipv6.address=none ipv4.address=none ipv4.nat=false
        echo -n " grp$grp"
    done
    echo
    echo "---> all networks created"
}

delete_networks () {
    echo "Deleting all networks..."
    lxc network list --format csv \
        | cut -d, -f1 \
        | grep -E '^grp[0-9]+-lan$' \
        | xargs -rt -n1 lxc network delete
    lxc network list --format csv \
        | cut -d, -f1 \
        | grep -E '^grp[0-9]+-int$' \
        | xargs -rt -n1 lxc network delete
    lxc network list --format csv \
        | cut -d, -f1 \
        | grep -E '^grp[0-9]+-dmz$' \
        | xargs -rt -n1 lxc network delete
    lxc network list --format csv \
        | cut -d, -f1 \
        | grep -E '^grp[0-9]+-extra$' \
        | xargs -rt -n1 lxc network delete
    echo "---> all networks deleted"
}