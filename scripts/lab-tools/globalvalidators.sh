#!/bin/bash

create_global_RPKI_validator () {
    echo "Creating global RPKI validators..."
    # rpkiX
    lxc copy RPKIfortX rpki1
    lxc copy RPKIfortX rpki2
    for serv in $(seq 1 2)
    do
        lxc config device add rpki${serv} eth0 nic name=eth0 nictype=bridged parent=net-bb
        echo " rpki${serv} server created"
    done
    echo "---> all global RPKI validators created"
}

delete_global_RPKI_validator () {
    echo "Deleting all global RPKI validators..."
    for serv in $(seq 1 2)
    do
        lxc delete rpki${serv} 2>/dev/null
    done
    echo "---> all global RPKI validators deleted"
}

start_global_RPKI_validator () {
    echo "Starting all global RPKI validators..."
    for serv in $(seq 1 2)
    do
        lxc start rpki${serv}
        lxc exec rpki${serv} -- cloud-init status --wait
        echo "global RPKI rpki$serv validator started"
    done
    echo "---> all global RPKI validators started"
}

stop_global_RPKI_validator () {
    echo "Stoping all global RPKI validators..."
    for serv in $(seq 1 2)
    do
        lxc stop -f rpki${serv} >/dev/null 2>&1
        echo "global RPKI rpki$serv validator stopped"
    done
    echo "---> all global RPKI validators stopped"
}

gen_global_RPKI_validator_net_config () {
    echo "Generating all student RPKI validators net conf..."
    for serv in $(seq 1 2)
    do
        nethost=$(( 69 + $serv ))
        sed -e "s|%GRP%|0|g" \
            -e "s|%NET%|0|g" \
            -e "s|%IP%|$nethost|g" \
            -e "s|%IPv6pfx%|$IPv6prefix|g" \
            ../configs/netplan/bb-lxc.yaml > $workdir/bb-lxc.yaml.rpki$serv
        echo "global RPKI validator net conf gen for rpki$serv done"
    done
}

push_global_RPKI_validator_net_config () {
    echo "Pushing global RPKI validators net conf..."
    for serv in $(seq 1 2)
    do
        echo "-- pushing network configuration files"
        lxc file push $workdir/bb-lxc.yaml.rpki$serv rpki$serv/etc/netplan/bb-lxc.yaml
        echo "-- setting host name to rpki$serv.$DOMAIN"
        lxc exec rpki$serv -- sh -c "echo rpki$serv.$DOMAIN >/etc/hostname"
        lxc exec rpki$serv -- "hostname rpki$serv.$DOMAIN"
        lxc exec rpki$serv -- sh -c "echo 127.0.0.222 rpki$serv.$DOMAIN >>/etc/hosts"
        echo "-- Stopping and starting rpki$serv"
        lxc stop rpki$serv
        lxc start rpki$serv
        echo "RPKI validator net conf push for rpki$serv done"
    done
}

push_global_RPKI_validator_files () {
    echo "Pushing global RPKI validators files..."
}
