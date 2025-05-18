#!/bin/bash

# Student Clients (computers in "lan" network)

create_student_clients () {
  echo "Creating all student clients..."
  for grp in $(seq 1 $NETWORKS)
  do
	  echo "grp$grp-cli"
	  lxc copy hostX grp${grp}-cli
	  lxc config device add grp${grp}-cli eth0 nic name=eth0 nictype=bridged parent=grp${grp}-lan
  done
  echo "---> all student clients created"
}

delete_student_clients () {
  echo "Deleting all student clients..."
  for grp in $(seq 1 $NETWORKS)
  do
  	lxc delete grp${grp}-cli 2>/dev/null
  done
  echo "---> all student clients deleted"

  # Deleting "lan-client-password-list" file that stores client passwords
  rm /var/shellinabox/lan-client-password-list.txt
  echo "/var/shellinabox/lan-client-password-list.txt file that stores celint passwords deleted!"
}

start_student_clients () {
  echo "Starting all student clients..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc start grp${grp}-cli
    echo "group $grp student client started"
  done
  for grp in $(seq 1 $NETWORKS)
  do
    lxc exec grp${grp}-cli -- cloud-init status --wait
    echo "group $grp student cloud init done"
  done
  echo "---> all student clients started"
}

stop_student_clients () {
  echo "Stopping all student clients..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc stop -f grp${grp}-cli >/dev/null 2>&1
    echo "group $grp student clinet stopped"
  done
  echo "---> all student clients stopped"
}

gen_student_clients_net_config () {
  echo "Generating all student clients net conf..."
  for grp in $(seq 1 $NETWORKS)
  do
    # Network 100.100.$grp.0/26 (lan)
    net=0
    gate=1
    for host in 1
    do
      nethost=$(( $net + $host + 1 ))
	    sed -e "s|%GRP%|$grp|g" \
	        -e "s|%NET%|$net|g" \
	        -e "s|%IP%|$nethost|g" \
          -e "s|%GATE%|$gate|g" \
          -e "s|%IPv6pfx%|$IPv6prefix|g" \
	        ../configs/netplan/10-lxc.yaml > $workdir/10-lxc.yaml.$grp-$net-$host
    done
    echo "Clients net (lan) conf gen for group $grp - network $net done"
  done
}

push_student_clients_net_config () {

  # Creating "lan-client-password-list" file to store client passwords
  # "lan-client-password-list" file will be stored in /var/shellinabox/lan-client-password-list.txt
  touch /var/shellinabox/lan-client-password-list.txt

  echo "Pushing all student clients net conf..."
  for grp in $(seq 1 $NETWORKS)
  do
    lxc file push $workdir/10-lxc.yaml.$grp-0-1 grp$grp-cli/etc/netplan/10-lxc.yaml
    lxc exec grp$grp-cli -- sh -c 'chmod 600 /etc/netplan/10-lxc.yaml'
    lxc exec grp$grp-cli -- sh -c "echo cli.grp$grp.$DOMAIN >/etc/hostname"
    lxc exec grp$grp-cli -- hostname cli.grp$grp.$DOMAIN
    lxc exec grp$grp-cli -- sh -c 'netplan apply'
    lxc exec grp$grp-cli -- sh -c "echo 127.0.0.222 cli.grp$grp.$DOMAIN >>/etc/hosts"

    # make cli use resolv1 and resolv2 as resolvers
    lxc exec grp$grp-cli -- sh -c "echo 'search grp$grp.$DOMAIN' >/etc/resolv.conf"
    lxc exec grp$grp-cli -- sh -c "echo 'nameserver 100.100.$grp.67' >>/etc/resolv.conf"
    lxc exec grp$grp-cli -- sh -c "echo 'nameserver 100.100.$grp.68' >>/etc/resolv.conf"

    echo "Clients net conf push for group $grp done"

    # Generating random password for user "sysadm"
    password=$(openssl rand -base64 14)
    # Pushing password to client container
    lxc exec grp$grp-cli -- sh -c "echo sysadm:$password | /usr/sbin/chpasswd"
    # Appending client password to "lan-client-password-list" file
    echo grp$grp-cli,$password >> /var/shellinabox/lan-client-password-list.txt
    echo "Generated sysadm grp$grp-cli password is: $password"
  done
}
