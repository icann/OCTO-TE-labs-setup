#!/bin/bash

#
# This files is for the management of the NS worker container
#
# The DNS worker container runs DNSdist to forward dns queries 
# to the right group container
#

create_ns1 () {
	echo "Start - Create NS1"
	lxc copy hostX ns1
    lxc start ns1
    lxc exec ns1 -- cloud-init status --wait
	lxc config device add ns1 eth0 nic name=eth0 nictype=bridged parent=net-bb
    # generating network config
	sed -e "s|%GRP%|0|g" \
	    -e "s|%NET%|0|g" \
	    -e "s|%IP%|53|g" \
      -e "s|%IPv6pfx%|$IPv6prefix|g" \
	    ../configs/netplan/bb-lxc.yaml > $workdir/bb-lxc.yaml.ns1
    # pushing network config..."
    lxc file push $workdir/bb-lxc.yaml.ns1 ns1/etc/netplan/bb-lxc.yaml
    lxc exec ns1 -- sh -c 'chmod 600 /etc/netplan/bb-lxc.yaml'
    lxc exec ns1 -- sh -c "echo ns1.$DOMAIN >/etc/hostname"
    lxc exec ns1 -- sh -c "hostname ns1.$DOMAIN"
    lxc exec ns1 -- sh -c "echo 127.0.0.222 ns1.$DOMAIN >>/etc/hosts"
    lxc exec ns1 -- sh -c 'netplan apply'
    lxc exec ns1 -- sh -c 'apt install dnsdist -y'
    # generating dnsdist config
	sed -e "s|%DOMAIN%|$DOMAIN|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
	    ../configs/dnsdist/dnsdist.conf > $workdir/dnsdist.conf
    lxc file push $workdir/dnsdist.conf ns1/etc/dnsdist/dnsdist.conf
    # dnsdist is a memory hog
    lxc config set ns1 limits.memory 4GB
    # restart server to apply all config changes 
    lxc stop ns1
    lxc start ns1
    lxc exec ns1 -- cloud-init status --wait
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
	echo "Done - Create NS1"
}

delete_ns1 () {
	echo "Start - Delete NS1"
	lxc delete ns1
    iptables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    iptables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination 100.64.0.53:53
    ip6tables -t nat -D PREROUTING -i eth0 -p udp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
    ip6tables -t nat -D PREROUTING -i eth0 -p tcp --dport 53 -j DNAT --to-destination [$IPv6prefix:0::53]:53
	echo "Done - Delete NS1"
}

start_ns1 () {
  echo "Start - Start NS!"
  lxc start ns1
  lxc exec dns -- cloud-init status --wait
  echo "Done - Start NS1"
}

stop_ns1 () {
  echo "Start - Stop NS1"
  lxc stop -f ns1 >/dev/null 2>&1
  echo "Done - Stop NS1"
}
