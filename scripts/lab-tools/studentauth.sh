#!/bin/bash

create_student_auth () {
    echo "Creating all student authoritative servers..."
    for grp in $(seq 1 $NETWORKS)
    do
        echo "Creating servers for grp$grp"
        lxc copy hostX grp${grp}-soa
        lxc copy hostX grp${grp}-ns1
        lxc copy hostX grp${grp}-ns2
        lxc config device add grp${grp}-soa eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
        lxc config device add grp${grp}-ns1 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-dmz
        lxc config device add grp${grp}-ns2 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-dmz
    done
    echo "---> all student authoritative servers created"
}

delete_student_auth () {
    echo "Deleting all student authoritative servers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc delete grp${grp}-soa 2>/dev/null
        lxc delete grp${grp}-ns1 2>/dev/null
        lxc delete grp${grp}-ns2 2>/dev/null
    done
    echo "Deleting student authoritative servers password list"
    rm /var/shellinabox/auth-server-password-list.txt
    echo "---> all student authoritative servers deleted"
}

start_student_auth () {
    echo "Starting all student authoritative servers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc start grp${grp}-soa
        lxc start grp${grp}-ns1
        lxc start grp${grp}-ns2
    done
    for grp in $(seq 1 $NETWORKS)
    do
        lxc exec grp${grp}-soa -- cloud-init status --wait
        lxc exec grp${grp}-ns1 -- cloud-init status --wait
        lxc exec grp${grp}-ns2 -- cloud-init status --wait
    done
    echo "---> all student authoritative servers started"
}

stop_student_auth () {
    echo "Stoping all student authoritative servers..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc stop -f grp${grp}-soa >/dev/null 2>&1
        lxc stop -f grp${grp}-ns1 >/dev/null 2>&1
        lxc stop -f grp${grp}-ns2 >/dev/null 2>&1
        echo "group $grp student authoritative servers stopped"
    done
    echo "---> all student authoritative servers stopped"
}

gen_student_auth_net_config () {
    echo "Generating all student authoritative servers net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        # Network 100.100.$grp.64/26 (int)
        net=64
        gate=65
        host=1
        nethost=$(( $net + $host + 1 ))
        sed -e "s|%GRP%|$grp|g" \
            -e "s|%NET%|$net|g" \
            -e "s|%IP%|$nethost|g" \
            -e "s|%GATE%|$gate|g" \
            -e "s|%IPv6pfx%|$IPv6prefix|g" \
            ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
        echo "Servers net (int) conf gen for group $grp - network $net done"

        # Network 100.100.$grp.128/26 (dmz)
        net=128
        gate=129
        for host in 1 2
        do
            nethost=$(( $net + $host + 1 ))
            sed -e "s|%GRP%|$grp|g" \
                -e "s|%NET%|$net|g" \
                -e "s|%IP%|$nethost|g" \
                -e "s|%GATE%|$gate|g" \
                -e "s|%IPv6pfx%|$IPv6prefix|g" \
                ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
        done
        echo "Servers net (dmz) conf gen for group $grp - network $net done"

    done
    echo "---> all student authoritative servers net conf generated"
}

push_student_auth_net_config () {
    echo "Creating password list file for student authoritative servers..."
    touch /var/shellinabox/auth-server-password-list.txt

    echo "Pushing all student authoritative servers net conf..."
    for grp in $(seq 1 $NETWORKS)
    do
        lxc file push $workdir/resolv.conf.$grp grp$grp-soa/etc/resolv.conf
        lxc file push $workdir/resolv.conf.$grp grp$grp-ns1/etc/resolv.conf
        lxc file push $workdir/resolv.conf.$grp grp$grp-ns2/etc/resolv.conf
        lxc file push $workdir/10-lxc.yaml.$grp-64-1 grp$grp-soa/etc/netplan/10-lxc.yaml
        lxc file push $workdir/10-lxc.yaml.$grp-128-1 grp$grp-ns1/etc/netplan/10-lxc.yaml
        lxc file push $workdir/10-lxc.yaml.$grp-128-2 grp$grp-ns2/etc/netplan/10-lxc.yaml
        lxc exec grp$grp-soa -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-ns1 -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-ns2 -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
        lxc exec grp$grp-soa -- sh -c "echo soa.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-ns1 -- sh -c "echo ns1.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-ns2 -- sh -c "echo ns2.grp$grp.$DOMAIN >/etc/hostname"
        lxc exec grp$grp-soa -- hostname soa.grp$grp.$DOMAIN
        lxc exec grp$grp-ns1 -- hostname ns1.grp$grp.$DOMAIN
        lxc exec grp$grp-ns2 -- hostname ns2.grp$grp.$DOMAIN
        lxc exec grp$grp-soa -- sh -c 'netplan apply'
        lxc exec grp$grp-ns1 -- sh -c 'netplan apply'
        lxc exec grp$grp-ns2 -- sh -c 'netplan apply'
        lxc exec grp$grp-soa -- sh -c "echo 127.0.0.222 soa.grp$grp.$DOMAIN >>/etc/hosts"
        lxc exec grp$grp-ns1 -- sh -c "echo 127.0.0.222 ns1.grp$grp.$DOMAIN >>/etc/hosts"
        lxc exec grp$grp-ns2 -- sh -c "echo 127.0.0.222 ns2.grp$grp.$DOMAIN >>/etc/hosts"
        echo "Servers net conf push for group $grp done"

        # Generating random password for user "sysadm"
        password=$(openssl rand -base64 14)
    
        # Pushing password to server containers and appending client password to "auth-server-password-list" file
        lxc exec grp$grp-soa -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
        echo grp$grp-soa,$password >> /var/shellinabox/auth-server-password-list.txt
        echo "Generated sysadm grp$grp-soa password is: $password"
        lxc exec grp$grp-ns1 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
        echo grp$grp-ns1,$password >> /var/shellinabox/auth-server-password-list.txt
        echo "Generated sysadm grp$grp-ns1 password is: $password"
        lxc exec grp$grp-ns2 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
        echo grp$grp-ns2,$password >> /var/shellinabox/auth-server-password-list.txt
        echo "Generated sysadm grp$grp-ns2 password is: $password"
    done
    echo "---> all student authoritative servers net conf pushed"
}
