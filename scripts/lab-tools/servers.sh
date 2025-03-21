#!/bin/bash

create_student_servers () {
  echo "Creating all student servers..."
  for grp in $(seq 1 $NETWORKS)
  do
  	echo "Creating servers for grp$grp"

  	# grpX-cli grpX-soa grpX-resolv1 grpX-resolv2 grpX-ns1 grpX-ns2
    lxc copy $server4resolv1 grp${grp}-resolv1
    lxc copy $server4resolv2 grp${grp}-resolv2
    
    lxc config device add grp${grp}-resolv1 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
    lxc config device add grp${grp}-resolv2 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int

    if [ $LABTYPE -gt 1 ]; then
      lxc copy $server4soa grp${grp}-soa
  	  lxc copy $server4ns1 grp${grp}-ns1
  	  lxc copy $server4ns2 grp${grp}-ns2

      lxc config device add grp${grp}-soa eth0 nic name=eth0 nictype=bridged parent=grp${grp}-int
  	  lxc config device add grp${grp}-ns1 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-dmz
  	  lxc config device add grp${grp}-ns2 eth0 nic name=eth0 nictype=bridged parent=grp${grp}-dmz
    fi
  done
  echo "---> all student servers created"
}

delete_student_servers () {
  echo "Deleting all student servers..."
  for grp in $(seq 1 $NETWORKS)
  do
  	lxc delete grp${grp}-resolv1 2>/dev/null
    lxc delete grp${grp}-resolv2 2>/dev/null

    lxc delete grp${grp}-soa 2>/dev/null
  	lxc delete grp${grp}-ns1 2>/dev/null
  	lxc delete grp${grp}-ns2 2>/dev/null
  done
  echo "---> all student servers deleted"

  # Deleting "*-server-password-list" files that stores servers passwords
  rm /var/shellinabox/int-server-password-list.txt
  rm /var/shellinabox/dmz-server-password-list.txt
  echo "/var/shellinabox/*-server-password-list.txt files that stores servers passwords deleted!"
}

start_student_servers () {
  echo "Starting all student servers..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc start grp${grp}-resolv1
    #lxc exec grp${grp}-resolv1 -- cloud-init status --wait
    
    lxc start grp${grp}-resolv2
    #lxc exec grp${grp}-resolv2 -- cloud-init status --wait

    if [ $LABTYPE -gt 1 ]; then
      lxc start grp${grp}-soa
      #lxc exec grp${grp}-soa -- cloud-init status --wait
      
      lxc start grp${grp}-ns1
      #lxc exec grp${grp}-ns1 -- cloud-init status --wait
      
      lxc start grp${grp}-ns2
      #lxc exec grp${grp}-ns2 -- cloud-init status --wait
    fi
    echo "group $grp student servers started"
  done
  echo "---> all student servers started"
}

stop_student_servers () {
  echo "Stoping all student servers..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc stop -f grp${grp}-resolv1 >/dev/null 2>&1
    lxc stop -f grp${grp}-resolv2 >/dev/null 2>&1

    lxc stop -f grp${grp}-soa >/dev/null 2>&1
    lxc stop -f grp${grp}-ns1 >/dev/null 2>&1
    lxc stop -f grp${grp}-ns2 >/dev/null 2>&1
    echo "group $grp student servers stopped"
  done
  echo "---> all student servers stopped"
}

gen_student_servers_net_config () {
  echo "Generating all student servers net conf..."
  for grp in $(seq 1 $NETWORKS)
  do

    # Network 100.100.$grp.64/26 (int)
    net=64
    gate=65
    for host in 1 2 3
    do
      nethost=$(( $net + $host + 1 ))
	    sed -e "s|%GRP%|$grp|g" \
	        -e "s|%NET%|$net|g" \
	        -e "s|%IP%|$nethost|g" \
          -e "s|%GATE%|$gate|g" \
          -e "s|%IPv6pfx%|$IPv6prefix|g" \
	        ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
    done
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

    # make cli use resolv1 and resolv2 as resolvers
    echo "search grp$grp.$DOMAIN"      >$workdir/resolv.conf.$grp
    echo "nameserver 100.100.$grp.67" >>$workdir/resolv.conf.$grp
    echo "nameserver 100.100.$grp.68" >>$workdir/resolv.conf.$grp

  done
}

push_student_servers_net_config () {

  # Creating "*-server-password-list" files to store servers passwords
  # "*-server-password-list" files will be stored in /var/shellinabox/*-server-password-list.txt
  touch /var/shellinabox/int-server-password-list.txt
  touch /var/shellinabox/dmz-server-password-list.txt

  echo "Pushing all student servers net conf..."
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

    if [ $LABTYPE -gt 1 ]; then
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
    fi
    echo "Servers net conf push for group $grp done"

    # Generating random password for user "sysadm"
    password=$(openssl rand -base64 14)
    
    # Pushing password to server containers and appending client password to "int-server-password-list" file
    lxc exec grp$grp-resolv1 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
    echo grp$grp-resolv1,$password >> /var/shellinabox/int-server-password-list.txt
    echo "Generted sysadm grp$grp-resolv1 password is: $password"
    
    lxc exec grp$grp-resolv2 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
    echo grp$grp-resolv2,$password >> /var/shellinabox/int-server-password-list.txt
    echo "Generted sysadm grp$grp-resolv2 password is: $password"
    
    if [ $LABTYPE -gt 1 ]; then
      lxc exec grp$grp-soa -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
      echo grp$grp-soa,$password >> /var/shellinabox/int-server-password-list.txt
      echo "Generated sysadm grp$grp-soa password is: $password"

      lxc exec grp$grp-ns1 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
      echo grp$grp-ns1,$password >> /var/shellinabox/int-server-password-list.txt
      echo "Generated sysadm grp$grp-ns1 password is: $password"

      lxc exec grp$grp-ns2 -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
      echo grp$grp-ns2,$password >> /var/shellinabox/int-server-password-list.txt
      echo "Generated sysadm grp$grp-ns2 password is: $password"
    fi
    
  done
}
