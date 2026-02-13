#!/bin/bash

#
# This files is for the management of the NS worker container
#
#

create_authns () {
    echo "Create authns"
    lxc copy hostX authns
    lxc start authns
    lxc exec authns -- cloud-init status --wait
    lxc config device add authns eth0 nic name=eth0 nictype=bridged parent=net-bb

    # generating network config
    sed -e "s|%GRP%|0|g" \
        -e "s|%NET%|0|g" \
        -e "s|%IP%|54|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-lxc.yaml > $workdir/bb-lxc.yaml.authns

    # generating .internal zone file
    sed -e "s|%GRP%|0|g" \
        -e "s|%NET%|0|g" \
        -e "s|%IP%|54|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        -e "s|%DOMAIN%|$DOMAIN|g" \
        ../configs/authns/db.internal > $workdir/db.internal.authns

    # pushing network config..."
    lxc file push $workdir/bb-lxc.yaml.authns authns/etc/netplan/bb-lxc.yaml
    lxc exec authns -- sh -c 'chmod 600 /etc/netplan/bb-lxc.yaml'
    lxc exec authns -- sh -c "echo authns.$DOMAIN >/etc/hostname"
    lxc exec authns -- sh -c "hostname authns.$DOMAIN"
    lxc exec authns -- sh -c "echo 127.0.0.222 authns.$DOMAIN >>/etc/hosts"
    lxc exec authns -- sh -c 'netplan apply'
    lxc exec authns -- sh -c 'apt install -qy bind9'

    # generating authns config
    lxc file push ../configs/authns/named.conf.options authns/etc/bind/named.conf.options
    lxc file push ../configs/authns/named.conf.local   authns/etc/bind/named.conf.local
    lxc exec authns -- sh -c 'chown -R bind:bind /etc/bind/*'
    lxc exec authns -- sh -c 'mkdir -p /var/lib/bind/zones'
    lxc file push $workdir/db.internal.authns authns/var/lib/bind/zones/db.internal
    lxc exec authns -- sh -c 'chown -R bind:bind /var/lib/bind'

    # restart server to apply all config changes 
    lxc stop authns
    lxc start authns
    lxc exec authns -- cloud-init status --wait

    # install nat rules on host
    iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination 100.64.0.54:53
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination 100.64.0.54:53
    ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::54]:53
    ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::54]:53
    #
    # save iptable rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    #
    echo "Done - Create authns"
}

delete_authns () {
    echo "Delete authns"
    lxc delete authns
    iptables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination 100.64.0.54:53
    iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination 100.64.0.54:53
    ip6tables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::54]:53
    ip6tables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::54]:53
    #
    # save iptable rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    #
    echo "Done - Delete authns"
}

start_authns () {
    echo "Start - authns!"
    lxc start authns
    lxc exec authns -- cloud-init status --wait
    echo "Done - Start authns"
}

stop_authns () {
    echo "Stop authns"
    lxc stop -f authns
    echo "Done - Stop authns"
}
