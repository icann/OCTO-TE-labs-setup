#!/bin/bash

create_student_RPKI_validator () {
    echo "Creating all student RPKI validators..."
    for grp in $(seq 1 $NETWORKS)
    do
        # grpX-rpki
        lxc copy RPKIfortX grp${grp}-rpki
        lxc config device add grp${grp}-rpki eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
        echo -n " grp$grp"
    done
    echo
    echo "---> all student RPKI validators created"
}

delete_student_RPKI_validator () {
    echo "Deleting all student RPKI validators..."
    lxc list -c n --format csv \
        | awk '/^grp[0-9]+-rpki$/ { print }' \
        | xargs -rt -n1 lxc delete --force    
    echo "---> all student RPKI validators deleted"
}

start_student_RPKI_validator () {
    echo "Starting all student RPKI validators..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc start grp${grp}-rpki
        #lxc exec grp${grp}-rpki -- cloud-init status --wait
        echo "group $grp student RPKI validator started"
    done
    echo "---> all student RPKI validators started"
}

stop_student_RPKI_validator () {
    echo "Stoping all student RPKI validators..."
    lxc list -c n --format csv \
        | awk '/^grp[0-9]+-rpki$/ { print }' \
        | xargs -rt -n1 lxc stop
    echo "---> all student RPKI validators stopped"
}

gen_student_RPKI_validator_net_config () {
    echo "Generating all student RPKI validators net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        # Network 100.100.$grp.64/26 (int)
        net=64
        gate=65
        for host in 5
        do
            nethost=$(( $net + $host + 1 ))
            sed -e "s|%GRP%|$grp|g" \
                -e "s|%NET%|$net|g" \
                -e "s|%IP%|$nethost|g" \
                -e "s|%GATE%|$gate|g" \
                -e "s|%IPv6pfx%|$IPv6prefix|g" \
                ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
        done
        echo "RPKI validator net (int) conf gen for group $grp - network $net done"
    done
}

push_student_RPKI_validator_net_config () {
    echo "Pushing all student RPKI validators net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc file push $workdir/10-lxc.yaml.$grp-64-5 grp$grp-rpki/etc/netplan/10-lxc.yaml
        lxc exec grp$grp-rpki -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-rpki -- sh -c "echo rpki.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-rpki -- hostname rpki.grp$grp.$DOMAIN
        lxc exec grp$grp-rpki -- sh -c 'netplan apply'
        lxc exec grp$grp-rpki -- sh -c "echo 127.0.0.222 rpki.grp$grp.$DOMAIN >>/etc/hosts"
        echo "RPKI validator net conf push for group $grp done"

        # Generating random password for user "sysadm"
        password=$(get_grp_password $grp)
    
        # Pushing password to RPKI validator containers and appending password to "int-RPKI-validator-password-list" file
        lxc exec grp$grp-rpki -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
    done
    echo "---> all student RPKI validators net conf pushed"
}

push_student_RPKI_validator_files () {
    echo "Pushing student RPKI validators files..."
}
