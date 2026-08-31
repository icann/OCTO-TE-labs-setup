#!/bin/bash
#
# dnsdist public DNS frontend management
#
# Container:
#   dnsdist
#
# Role:
#   Public DNS frontend / dispatcher
#
# Addresses:
#   IPv4: 100.64.0.53
#   IPv6: $IPv6prefix:0::53
#

create_dnsdist () {
    echo "Start - Create dnsdist"

    lxc copy hostX dnsdist
    lxc start dnsdist
    lxc exec dnsdist -- cloud-init status --wait

    #
    # Network
    #
    lxc config device add dnsdist eth0 nic \
        name=eth0 \
        nictype=bridged \
        parent=net-bb

    sed -e "s|%GRP%|0|g" \
        -e "s|%NET%|0|g" \
        -e "s|%IP%|53|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-lxc.yaml \
        > $workdir/bb-lxc.yaml.dnsdist

    lxc file push \
        $workdir/bb-lxc.yaml.dnsdist \
        dnsdist/etc/netplan/bb-lxc.yaml

    lxc exec dnsdist -- sh -c \
        'chmod 600 /etc/netplan/bb-lxc.yaml'

    #
    # Host identity
    #
    lxc exec dnsdist -- sh -c \
        "echo dnsdist.$DOMAIN >/etc/hostname"

    lxc exec dnsdist -- sh -c \
        "hostname dnsdist.$DOMAIN"

    lxc exec dnsdist -- sh -c \
        "echo 127.0.0.222 dnsdist.$DOMAIN >>/etc/hosts"

    lxc exec dnsdist -- sh -c \
        'netplan apply'

    #
    # Install dnsdist
    #
    lxc exec dnsdist -- sh -c \
        'apt install -qy dnsdist'

    #
    # Generate base dnsdist configuration
    #
    sed -e "s|%DOMAIN%|$DOMAIN|g" \
        -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/dnsdist/dnsdist.conf \
        > $workdir/dnsdist.conf

    #
    # Group authoritative pools and routing rules
    #
    # These pools are only needed when student authoritative
    # DNS servers are part of the selected lab.
    #
    if [ "$StudentAuth" = "YES" ]; then
        for grp in $(seq 1 $NETWORKS)
        do
            cat >> $workdir/dnsdist.conf <<EOF

--
-- grp${grp} authoritative DNS
--
newServer({
    address="${IPv6prefix}:${grp}:128::130",
    pool="grp${grp}",
    healthCheckMode='lazy',
    checkInterval=30
}):setUp()

newServer({
    address="${IPv6prefix}:${grp}:128::131",
    pool="grp${grp}",
    healthCheckMode='lazy',
    checkInterval=30
}):setUp()

newServer({
    address="100.100.${grp}.130",
    pool="grp${grp}",
    healthCheckMode='lazy',
    checkInterval=30
}):setUp()

newServer({
    address="100.100.${grp}.131",
    pool="grp${grp}",
    healthCheckMode='lazy',
    checkInterval=30
}):setUp()

--
-- The DS for grp${grp}.${DOMAIN} belongs to the parent zone
-- and must therefore be answered by auth-platform.
--
addAction(
    AndRule({
        QNameRule("grp${grp}.${DOMAIN}"),
        QTypeRule(DNSQType.DS)
    }),
    PoolAction("auth-platform")
)

--
-- All other queries at or below grp${grp}.${DOMAIN} are answered
-- by the authoritative servers belonging to the group.
--
grp${grp}Suffix = newSuffixMatchNode()
grp${grp}Suffix:add("grp${grp}.${DOMAIN}")

addAction(
    SuffixMatchNodeRule(grp${grp}Suffix),
    PoolAction("grp${grp}")
)
EOF
        done
    fi

    #
    # Platform authoritative DNS
    #
    # Queries not matched by a group rule are handled by ns1.
    #
    cat >> $workdir/dnsdist.conf <<EOF

--
-- Platform authoritative DNS
--
addAction(
    AllRule(),
    PoolAction("auth-platform")
)
EOF

    #
    # Push dnsdist configuration
    #
    lxc file push \
        $workdir/dnsdist.conf \
        dnsdist/etc/dnsdist/dnsdist.conf

    #
    # dnsdist memory limit
    #
    lxc config set dnsdist limits.memory 8GB

    #
    # Restart server to apply final configuration
    #
    lxc stop dnsdist
    lxc start dnsdist
    lxc exec dnsdist -- cloud-init status --wait

    #
    # Public DNS DNAT
    #
    iptables -t nat -A PREROUTING \
        -i eth0 \
        -p udp \
        --dport 53 \
        -j DNAT \
        --to-destination 100.64.0.53:53

    iptables -t nat -A PREROUTING \
        -i eth0 \
        -p tcp \
        --dport 53 \
        -j DNAT \
        --to-destination 100.64.0.53:53

    ip6tables -t nat -A PREROUTING \
        -i eth0 \
        -p udp \
        --dport 53 \
        -j DNAT \
        --to-destination [$IPv6prefix:0::53]:53

    ip6tables -t nat -A PREROUTING \
        -i eth0 \
        -p tcp \
        --dport 53 \
        -j DNAT \
        --to-destination [$IPv6prefix:0::53]:53

    #
    # Save firewall rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6

    echo "Done - Create dnsdist"
}


delete_dnsdist () {
    echo "Start - Delete dnsdist"

    lxc delete dnsdist

    iptables -t nat -D PREROUTING \
        -i eth0 \
        -p udp \
        --dport 53 \
        -j DNAT \
        --to-destination 100.64.0.53:53

    iptables -t nat -D PREROUTING \
        -i eth0 \
        -p tcp \
        --dport 53 \
        -j DNAT \
        --to-destination 100.64.0.53:53

    ip6tables -t nat -D PREROUTING \
        -i eth0 \
        -p udp \
        --dport 53 \
        -j DNAT \
        --to-destination [$IPv6prefix:0::53]:53

    ip6tables -t nat -D PREROUTING \
        -i eth0 \
        -p tcp \
        --dport 53 \
        -j DNAT \
        --to-destination [$IPv6prefix:0::53]:53

    #
    # Save firewall rules for reboot
    #
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6

    echo "Done - Delete dnsdist"
}


start_dnsdist () {
    echo "Start - dnsdist"

    lxc start dnsdist
    lxc exec dnsdist -- cloud-init status --wait

    echo "Done - Start dnsdist"
}


stop_dnsdist () {
    echo "Start - Stop dnsdist"

    lxc stop -f dnsdist

    echo "Done - Stop dnsdist"
}