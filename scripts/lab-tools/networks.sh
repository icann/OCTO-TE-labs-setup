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
    for grp in $(seq 1 $NETWORKS)
    do
        lxc network delete grp${grp}-lan 2>/dev/null
        lxc network delete grp${grp}-int 2>/dev/null
        lxc network delete grp${grp}-dmz 2>/dev/null
        lxc network delete grp${grp}-extra 2>/dev/null
    done
    echo "---> all networks deleted"
}