#!/bin/bash

#
# This files is for the management of the NS worker container
#
# The DNS worker container runs DNSdist to forward dns queries 
# to the right group container
#

create_dnsdist () {
    echo "Start - Create dnsdist"
    lxc copy hostX dnsdist
    lxc start dnsdist
    lxc exec dnsdist -- cloud-init status --wait
    lxc config device add dnsdist eth0 nic name=eth0 nictype=bridged parent=net-bb
    # generating network config
    sed -e "s|%GRP%|0|g" \
        -e "s|%NET%|0|g" \
        -e "s|%IP%|53|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-lxc.yaml > $workdir/bb-lxc.yaml.dnsdist
    # pushing network config..."
    lxc file push $workdir/bb-lxc.yaml.dnsdist dnsdist/etc/netplan/bb-lxc.yaml
    lxc exec dnsdist -- sh -c 'chmod 600 /etc/netplan/bb-lxc.yaml'
    lxc exec dnsdist -- sh -c "echo dnsdist.$DOMAIN >/etc/hostname"
    lxc exec dnsdist -- sh -c "hostname dnsdist.$DOMAIN"
    lxc exec dnsdist -- sh -c "echo 127.0.0.222 dnsdist.$DOMAIN >>/etc/hosts"
    lxc exec dnsdist -- sh -c 'netplan apply'
    lxc exec dnsdist -- sh -c 'apt install dnsdist -y'
    # generating dnsdist config
    sed -e "s|%DOMAIN%|$DOMAIN|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/dnsdist/dnsdist.conf > $workdir/dnsdist.conf
    lxc file push $workdir/dnsdist.conf dnsdist/etc/dnsdist/dnsdist.conf
    # dnsdist is a memory hog
    lxc config set dnsdist limits.memory 8GB
    # restart server to apply all config changes 
    lxc stop dnsdist
    lxc start dnsdist
    lxc exec dnsdist -- cloud-init status --wait
    # install nat rules on host
    iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
    ip6tables -t nat -A PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
    #
    # save iptable rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    #
    echo "Done - Create dnsdist"
}

delete_dnsdist () {
    echo "Start - Delete dnsdist"
    lxc delete dnsdist
    iptables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    ip6tables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
    ip6tables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
    #
    # save iptable rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    #
    echo "Done - Delete dnsdist"
}

start_dnsdist () {
    echo "Start - DNSdist!"
    lxc start dnsdist
    lxc exec dns -- cloud-init status --wait
    echo "Done - Start DNSdist"
}

stop_dnsdist () {
    echo "Start - Stop dnsdist"
    lxc stop -f dnsdist
    echo "Done - Stop dnsdist"
}
