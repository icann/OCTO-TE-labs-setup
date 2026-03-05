#!/bin/bash

create_student_resolvers () {
    echo "Creating all student resolvers..."
    for grp in $(seq 1 $NETWORKS)
    do
        echo "Creating resolvers for grp$grp"
        lxc copy hostX grp${grp}-resolv1
        lxc copy hostX grp${grp}-resolv2
        lxc config device add grp${grp}-resolv1 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
        lxc config device add grp${grp}-resolv2 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
    done
    echo "---> all student resolvers created"
}

delete_student_resolvers () {
    echo "Deleting all student resolvers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc delete grp${grp}-resolv1 2>/dev/null
        lxc delete grp${grp}-resolv2 2>/dev/null
    done
    echo "---> all student resolvers deleted"

    echo "Deleting student resolvers password list"
    rm /var/shellinabox/res-server-password-list.txt
    echo "---> all student resolvers deleted"
}

start_student_resolvers () {
    echo "Starting all student resolvers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc start grp${grp}-resolv1
        lxc start grp${grp}-resolv2
    done
    for grp in $(seq 1 $NETWORKS)
    do
        lxc exec grp${grp}-resolv1 -- cloud-init status --wait
        lxc exec grp${grp}-resolv2 -- cloud-init status --wait
    done
    echo "---> all student resolvers started"
}

stop_student_resolvers () {
    echo "Stoping all student resolvers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc stop -f grp${grp}-resolv1 >/dev/null 2>&1
        lxc stop -f grp${grp}-resolv2 >/dev/null 2>&1
        echo "group $grp student resolvers stopped"
    done
    echo "---> all student resolvers stopped"
}

gen_student_resolvers_net_config () {
    echo "Generating all student resolvers net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        # Network 100.100.$grp.64/26 (int)
        net=64
        gate=65
        for host in 2 3
        do
            nethost=$(( $net + $host + 1 ))
            sed -e "s|%GRP%|$grp|g" \
                -e "s|%NET%|$net|g" \
                -e "s|%IP%|$nethost|g" \
                -e "s|%GATE%|$gate|g" \
                -e "s|%IPv6pfx%|$IPv6prefix|g" \
                ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
        done
        echo "resolvers net (int) conf gen for group $grp - network $net done"

        # make cli use resolv1 and resolv2 as resolvers
        echo "search grp$grp.$DOMAIN"      >$workdir/resolv.conf.$grp
        echo "nameserver 100.100.$grp.67" >>$workdir/resolv.conf.$grp
        echo "nameserver 100.100.$grp.68" >>$workdir/resolv.conf.$grp
        echo "nameserver $IPv6prefix:$grp:64::67" >>$workdir/resolv.conf.$grp
        echo "nameserver $IPv6prefix:$grp:64::68" >>$workdir/resolv.conf.$grp
    done
}

push_student_resolvers_net_config () {
    echo "Creating password list file for student resolvers..."
    touch /var/shellinabox/res-server-password-list.txt

    echo "Pushing all student resolvers net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc file push $workdir/resolv.conf.$grp grp$grp-resolv1/etc/resolv.conf
        lxc file push $workdir/resolv.conf.$grp grp$grp-resolv2/etc/resolv.conf
        lxc file push $workdir/10-lxc.yaml.$grp-64-2 grp$grp-resolv1/etc/netplan/10-lxc.yaml
        lxc file push $workdir/10-lxc.yaml.$grp-64-3 grp$grp-resolv2/etc/netplan/10-lxc.yaml
        lxc exec grp$grp-resolv1 -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-resolv2 -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-resolv1 -- sh -c "echo resolv1.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-resolv2 -- sh -c "echo resolv2.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-resolv1 -- hostname resolv1.grp$grp.$DOMAIN
        lxc exec grp$grp-resolv2 -- hostname resolv2.grp$grp.$DOMAIN
        lxc exec grp$grp-resolv1 -- sh -c 'netplan apply'
        lxc exec grp$grp-resolv2 -- sh -c 'netplan apply'
        lxc exec grp$grp-resolv1 -- sh -c "echo 127.0.0.222 resolv1.grp$grp.$DOMAIN >>/etc/hosts"
        lxc exec grp$grp-resolv2 -- sh -c "echo 127.0.0.222 resolv2.grp$grp.$DOMAIN >>/etc/hosts"
        echo "resolvers net conf push for group $grp done"

        # Generating random password for user "sysadm"
        password=$(openssl rand -base64 14)
    
        # Pushing password to server containers and appending client password to "res-server-password-list" file
        lxc exec grp$grp-resolv1 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
        echo grp$grp-resolv1,$password >> /var/shellinabox/res-server-password-list.txt
        echo "Generted sysadm grp$grp-resolv1 password is: $password"
    
        lxc exec grp$grp-resolv2 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
        echo grp$grp-resolv2,$password >> /var/shellinabox/res-server-password-list.txt
        echo "Generted sysadm grp$grp-resolv2 password is: $password"
    done
    echo "---> all student resolvers net conf pushed"
}
