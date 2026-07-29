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
    lxc list -c n --format csv \
        | grep -E '^grp[0-9]+-lan$' \
        | xargs -r -n1 lxc network delete --force    
    lxc list -c n --format csv \
        | grep -E '^grp[0-9]+-int$' \
        | xargs -r -n1 lxc network delete --force    
    lxc list -c n --format csv \
        | grep -E '^grp[0-9]+-dmz$' \
        | xargs -r -n1 lxc network delete --force    
    lxc list -c n --format csv \
        | grep -E '^grp[0-9]+-extra$' \
        | xargs -r -n1 lxc network delete --force    
    echo "---> all networks deleted"
}