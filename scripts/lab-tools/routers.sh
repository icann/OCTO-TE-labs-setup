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

create_border_router () {
  echo "Creating border router..."
  # Create router to serve as border router (peering with all group routers)
  echo "Create iborder-rtr router (this will be the border router, for example in Anycast labs)..."
  echo "Create router (iborder-rtr) from rtrX"
  lxc copy rtrX iborder-rtr
  echo " "
  echo "---> border router created"
}

delete_routers () {
  echo "Deleting all routers..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc delete grp${grp}-rtr 2>/dev/null
    echo "-- deletting grp$grp-rtr"
  done
  echo "---> all routers deleted"

  # Deleting "router-password-list" file that stores router passwords
  rm /var/shellinabox/router-password-list.txt
  echo "/var/shellinabox/router-password-list.txt file that stores router passwords deleted!"
}

delete_border_router () {
  echo "-- deleting NAT rule to forward VPN connection to iborder-rtr (destination 100.64.0.10:36456)..."
  iptables -t nat -D PREROUTING -i eth0 -p udp --dport 36456 -j DNAT --to-destination 100.64.0.10:36456
  echo "-- deleting iborder-rtr"
  lxc delete iborder-rtr 2>/dev/null
  echo "---> iborder-rtr router deleted"
}

start_routers () {
  echo "Starting all routers..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc start grp${grp}-rtr
    #lxc exec grp${grp}-rtr -- cloud-init status --wait
	  echo -n " grp$grp-rtr started"
  done
  for grp in $(seq 1 $NETWORKS)
  do
    lxc exec grp${grp}-rtr -- cloud-init status --wait
  done
  echo " "
  echo "---> all routers started"
}

start_border_router () {
  echo "Starting iborder-rtr"
  lxc start iborder-rtr
  lxc exec iborder-rtr -- cloud-init status --wait
  echo " "
  echo "---> iborder-rtr router started"
}

stop_routers () {
  echo "Stopping all routers..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc stop -f grp${grp}-rtr >/dev/null 2>&1
	  echo -n " grp$grp-rtr stopped"
  done
  echo " "
  echo "---> all routers stopped"
}

stop_border_router () {
  echo "Stopping iborder-rtr"
  lxc stop -f iborder-rtr >/dev/null 2>&1
  echo " "
  echo "---> iborder-rtr router stopped"
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

gen_border_router_net_config () {
  ### Generate iborder-rtr config
  echo "Generating iborder-rtr config..."
  sed -e "s|%RTR%|$rtr|g" \
      -e "s|%DOM%|$DOMAIN|g" \
      -e "s|%IPv6pfx%|$IPv6prefix|g" \
	    ../configs/iborder-rtr/iborder-rtr > $workdir/iborder-rtr.conf
  
  # Create temporary files to store BGP configuration
  echo "Creating temporary files to store BGP configuration..."
  touch $workdir/iborder-rtr-neighbors_IPv4-bgp.conf
  touch $workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
  touch $workdir/iborder-rtr-neighbors_IPv6-bgp.conf
  touch $workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf

  # Generate BGP IPv4 configuration
  echo "Generating BGP IPv4 configuration..."
  for grp in $(seq 1 $NETWORKS)
  do
    grp_asn=`expr 65000 + $grp`
    echo " neighbor 100.64.1.$grp remote-as $grp_asn" >>$workdir/iborder-rtr-neighbors_IPv4-bgp.conf
    echo " neighbor 100.64.1.$grp description grp$grp-rtr" >>$workdir/iborder-rtr-neighbors_IPv4-bgp.conf
    echo "  neighbor 100.64.1.$grp activate" >>$workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
    echo "  neighbor 100.64.1.$grp soft-reconfiguration inbound" >>$workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
    echo "  neighbor 100.64.1.$grp route-map TODO-IPv4 in" >>$workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
    echo "  neighbor 100.64.1.$grp route-map TODO-IPv4 out" >>$workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
    #echo "  neighbor 100.64.1.$grp route-map NADA out" >>$workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
  done
  echo "BGP IPv4 neighbor config:"
  cat $workdir/iborder-rtr-neighbors_IPv4-bgp.conf
  echo " "
  echo "BGP IPv4 address family config:"
  cat $workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf
  echo " "

  # Generate BGP IPv6 configuration
  echo "Generating BGP IPv6 configuration..."
  for grp in $(seq 1 $NETWORKS)
  do
    grp_asn=`expr 65000 + $grp`
    echo " neighbor $IPv6prefix:0:1::$grp remote-as $grp_asn" >>$workdir/iborder-rtr-neighbors_IPv6-bgp.conf
    echo " neighbor $IPv6prefix:0:1::$grp description grp$grp-rtr" >>$workdir/iborder-rtr-neighbors_IPv6-bgp.conf
    echo "  neighbor $IPv6prefix:0:1::$grp activate" >>$workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
    echo "  neighbor $IPv6prefix:0:1::$grp soft-reconfiguration inbound" >>$workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
    echo "  neighbor $IPv6prefix:0:1::$grp route-map TODO-IPv6 in" >>$workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
    echo "  neighbor $IPv6prefix:0:1::$grp route-map TODO-IPv6 out" >>$workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
    #echo "  neighbor $IPv6prefix:0:1::$grp route-map NADA_IPv6 out" >>$workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
  done
  echo "BGP IPv6 neighbor config:"
  cat $workdir/iborder-rtr-neighbors_IPv6-bgp.conf
  echo " "
  echo "BGP IPv6 address family config:"
  cat $workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf
  echo " "
  
  # Add all configurations in iborder-rtr router config file (iborder-rtr.conf)
  echo "Adding all configurations in iborder-rtr router config file..."
  sed -i -e "/%bgp_neighbors_IPv4%/r $workdir/iborder-rtr-neighbors_IPv4-bgp.conf" -e "/%bgp_neighbors_IPv4%/d" $workdir/iborder-rtr.conf
  sed -i -e "/%bgp_addr_family_IPv4%/r $workdir/iborder-rtr-neighbors_IPv4-bgp-addr_family.conf" -e "/%bgp_addr_family_IPv4%/d" $workdir/iborder-rtr.conf
  sed -i -e "/%bgp_neighbors_IPv6%/r $workdir/iborder-rtr-neighbors_IPv6-bgp.conf" -e "/%bgp_neighbors_IPv6%/d" $workdir/iborder-rtr.conf
  sed -i -e "/%bgp_addr_family_IPv6%/r $workdir/iborder-rtr-neighbors_IPv6-bgp-addr_family.conf" -e "/%bgp_addr_family_IPv6%/d" $workdir/iborder-rtr.conf
  echo " "
  cat $workdir/iborder-rtr.conf
  echo " "
  echo "---> iborder-rtr config created"
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

push_border_router_net_config () {
  echo "Pushing iborder-rtr config..."
  lxc exec iborder-rtr -- bash -ilc 'systemctl stop frr'
  echo "-- Pushing configuration file (iborder-rtr/etc/frr/frr.conf)..."
  lxc file push $workdir/iborder-rtr.conf iborder-rtr/etc/frr/frr.conf
  lxc exec iborder-rtr -- bash -ilc 'chown frr:frr /etc/frr/frr.conf'
  echo "-- Restarting frr@iborder-rtr service..."
  lxc exec iborder-rtr -- bash -ilc 'systemctl start frr'
  echo " "
  echo "---> border router config pushed"
}

config_iborder_rtr_VPN_with_ISP () {
  echo "Adding NAT rule to forward VPN connection to iborder-rtr (destination 100.64.0.10:36456)..."
  iptables -t nat -A PREROUTING -i eth0 -p udp --dport 36456 -j DNAT --to-destination 100.64.0.10:36456

  echo "Configuring iborder-rtr VPN..."
  # Install VPN packages & set up interface for VPN
  lxc exec iborder-rtr -- bash -ilc "
    apt-get -yq update
    apt-get -yq install wireguard wireguard-tools wireguard-dkms
    ip link add wg0 type wireguard
    ip addr add $VPNlocalIPv4 dev wg0
    ip link set wg0 up
    "
    sed -e "s|%VPNlistenPort%|$VPNlistenPort|g" \
	      -e "s|%VPNprivateKey%|$VPNprivateKey|g" \
	      -e "s|%VPNpublicKey%|$VPNpublicKey|g" \
        -e "s|%VPNallowedPrefixIPv4%|$VPNallowedPrefixIPv4|g" \
        -e "s|%VPNendPointIPv4%|$VPNendPointIPv4|g" \
	      ../configs/iborder-rtr/VPN_with_ISPs/wireguard/etc/wireguard/wg0.conf > $workdir/wireguard-$VPNpeerName-wg0.conf
    lxc file push $workdir/wireguard-$VPNpeerName-wg0.conf iborder-rtr/etc/wireguard/wg0.conf
    lxc exec iborder-rtr -- bash -ilc "
    cd /root
    echo $VPNprivateKey > wg0.private
    chmod 400 wg0.private
    wg-quick down wg0
    wg-quick up wg0
    systemctl enable wg-quick@wg0
    "
  # Display wg config and status
  echo "---> wg config: "
  lxc exec iborder-rtr -- bash -ilc "wg showconf wg0"
  echo " "
  echo "---> wg status: "
  lxc exec iborder-rtr -- bash -ilc "wg"
  echo " "
}
