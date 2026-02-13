#!/bin/bash

# Routers

create_routers () {
    echo "Creating all routers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc copy rtrX grp${grp}-rtr
        # eth0 creation is implicit - depends on default profile
        lxc config device add grp${grp}-rtr eth1 nic name=eth1 nictype=bridged parent=grp${grp}-lan
        lxc config device add grp${grp}-rtr eth2 nic name=eth2 nictype=bridged parent=grp${grp}-int
        lxc config device add grp${grp}-rtr eth3 nic name=eth3 nictype=bridged parent=grp${grp}-dmz
        lxc config device add grp${grp}-rtr eth4 nic name=eth4 nictype=bridged parent=grp${grp}-extra
    done
    echo " "
    echo "---> all routers created"
}

delete_routers () {
    echo "Deleting all routers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc delete grp${grp}-rtr 2>/dev/null
        echo "-- deleting grp$grp-rtr"
    done
    echo "---> all routers deleted"

    # Deleting "router-password-list" file that stores router passwords
    rm /var/shellinabox/router-password-list.txt
    echo "/var/shellinabox/router-password-list.txt file that stores router passwords deleted!"
}

start_routers () {
    echo "Starting all routers..."
    for grp in $(seq 1 $NETWORKS)
    do
        echo -n "  starting grp$grp-rtr"
        lxc start grp${grp}-rtr
    done
    for grp in $(seq 1 $NETWORKS)
    do
        echo -n "  waiting for grp$grp-rtr"
        lxc exec grp${grp}-rtr -- cloud-init status --wait
    done
    echo
    echo "All routers started"
}

stop_routers () {
    echo "Stopping all routers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc stop -f grp${grp}-rtr >/dev/null 2>&1
        echo -n " grp$grp-rtr"
    done
    echo " "
    echo "---> all routers stopped"
}

gen_routers_net_config () {
    echo "Generating all routers configs..."
    rtr=1
    for grp in $(seq 1 $NETWORKS)
    do
        bbgrp=`expr 0 + $grp`
        echo "bbgrp: $bbgrp"
        sed -e "s|%RTR%|$rtr|g" \
            -e "s|%DOM%|$DOMAIN|g" \
            -e "s|%NET%|$grp|g" \
            -e "s|%BBNET%|$bbgrp|g" \
            -e "s|%IPv6pfx%|$IPv6prefix|g" \
            ../configs/rtr/frr > $workdir/frr.conf.$grp
    done
    echo " "
}

push_routers_net_config () {
    # Creating "router-password-list" file to store router passwords
    # "router-password-list" file will be stored in /var/shellinabox/router-password-list.txt
    touch /var/shellinabox/router-password-list.txt

    echo "Pushing all routers configs..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc file push $workdir/frr.conf.$grp grp$grp-rtr/etc/frr/frr.conf
        lxc exec grp$grp-rtr -- sh -c 'chown frr:frr /etc/frr/frr.conf'
        lxc exec grp$grp-rtr -- sh -c 'service frr restart'

        # Generating random password for user "rtradm"
        password=$(openssl rand -base64 14)
        # Pushing password to router container
        lxc exec grp$grp-rtr -- sh -c "echo rtradm:$password | /usr/sbin/chpasswd"
        # Appending router password to "router-password-list" file
        echo grp$grp-rtr,$password >> /var/shellinabox/router-password-list.txt
        echo "-- Generated rtradm grp$grp-rtr password is: $password"

        echo "-- grp$grp-rtr done"
    done
    echo " "
    echo "---> all routers configs pushed"
}
