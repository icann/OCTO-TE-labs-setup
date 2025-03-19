#!/bin/bash

set -exou

# +++++++++++++++++++++++++++++++++++++
# Created by Nicolas Antoniello @ICANN
# +++++++++++++++++++++++++++++++++++++

## You'll have to run this script only once, right after initiating a new cloud lab instance

DOMAIN=$1
DOMAIN=`echo $DOMAIN | perl -n -e "s/\.$//;print $_;"`
IPV4=$2
IPV6=`ip a s dev eth0 scope global | perl -n -e'print $1 if m/inet6\s+(\S+)\/128/'`
ZONEID=$3
LABTYPE=$4
NETWORKS=$5

# ------------------------------------------------------------------------------------------------------------------
# ---------------------------------------- DEFAULT CONFIGURATIONS SET UP -------------------------------------------

## General initial variables (will need all this for the rest of the script)

# Set the ammount of RAM (in GB) you server is going to use for swap purpose (for example 8G for a 8GB RAM server)
# If the Lab server instance has more than 10GB memory, we will leave this value in 10GB as it'll be used for swap set-up.
instanceRAMsize=$(free -g | awk 'FNR == 2 {print $2}')
## Make sure you have at least twice the ammount of free disk space than the ammount of RAM, 
## so as to use it for swap file setup.
if [ "$instanceRAMsize" -gt "10" ]; then
  SWAPsize="10G"
else
  SWAPsize=$instanceRAMsize"G"
fi
echo "---> Swap file size set to $SWAPsize"
echo " "

# Getting the actual MAC addr for the network interface of the instance
# The same it should be in the actual /etc/netplan/50-cloud-init.yaml file
apt-get -yq update
apt-get -yq install net-tools
echo "-----------------------------------------------------------------------"
echo " "
instanceMACaddr="$(cat /etc/netplan/50-cloud-init.yaml | grep "macaddress:" | awk '{print $2}')"
# Attempt another way of getting MAC addr if previous one fails
if [ -z "$instanceMACaddr" ]; then
    echo "-- Could not find MAC Addr looking at /etc/netplan/50-cloud-init.yaml, trying another way..."
    instanceMACaddr="$(ifconfig | grep "ether" | awk 'NR==1{print $2}')"
fi
# If could not find MAC addr to use, then exit script
if [ -z "$instanceMACaddr" ]; then
    echo "-- Could not find MAC address to use... EXITING (could not proceed !)"
    exit 5
fi
echo "---> Using MAC address for eth0: $instanceMACaddr"

# ------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------

main() {

  workdir=/tmp/cloud_init
  mkdir -p $workdir/etc/netplan
  
  ## Initial update/upgrade and basic set-up
  echo "---> Initial update/upgrade and basic set-up..."
  echo " "
  init_lab_VM
  echo " "
  echo "-----------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------"

  ## Set up new sysctl.conf system parameters
  # Backup of current /etc/sysctl.conf file
  cp -n /etc/sysctl.conf /etc/sysctl.conf.original-"$(date +\%F_\%H-\%M-\%S)"
  echo "-- Backup of currect /etc/sysctl.conf file done!"
  echo "-- Pushing new /etc/sysctl.conf file..."
  cp ../configs/sysctl/etc/sysctl.conf /etc/sysctl.conf
  echo "-- Applying new /etc/sysctl.conf parameters..."
  sysctl -p
  echo " "
  echo "-----------------------------------------------------------------------"

  ## Setup swap file (if there is no one already)
  echo "-- Checking for swap file ..."
  if free | awk '/^Swap:/ {exit !$2}'; then
    echo "System already have a defined swap file!"
    echo " "
  else
    echo "No swap space found; will generate ..."
    echo " "
    define_swap_space
  fi

  echo "-----------------------------------------------------------------------"

  ## Generate IPv6 ULA prefix
  generate_IPv6_ULA

  echo "-----------------------------------------------------------------------"

  ## generate and apply new netplan for the Lab
  echo "---> Generate and apply new netplan for the Lab"
  echo " "

  # Backup of current /etc/netplan/50-cloud-init.yaml file
  cp -n /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.original-"$(date +\%F_\%H-\%M-\%S)"
  echo "-- Backup of currect /etc/netplan/50-cloud-init.yaml file done!"
  echo " "

  gen_net_config
  push_net_config

  # Enable NAT (so the hosts on 100.64.0.0/10 can reach the outside world)
  # by creating "/etc/networkd-dispatcher/routable.d/50-net-bb" and make it executable (chmod +x)
  cp ../configs/net-dispatcher/etc/networkd-dispatcher/routable.d/50-net-bb /etc/networkd-dispatcher/routable.d/50-net-bb
  chmod +x /etc/networkd-dispatcher/routable.d/50-net-bb

  # Apply new netplan (this --debug will output a lot of stuff... but it'll be useful if something goes wrong)
  netplan generate
  netplan --debug apply
  echo " "

  echo "-----------------------------------------------------------------------"

  # Set-up a DHCP server to be used during container initial set-up
  setup_DHCP_server

  # Initialize LXD
  LXD_init


  ## generate "deploy-parameters.cfg" file to be used by "deploy.sh" script
  echo " "
  echo "---> Generting deploy-parameters.cfg file to be used by deploy.sh script... "

  sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
    ../configs/deploy-parameters.cfg > ./deploy-parameters.cfg
  
  sed -i -e "s/%LABDOMAIN%/${DOMAIN}/" ./deploy-parameters.cfg
  sed -i -e "s/%IPV4ADDRESS%/${IPV4}/" ./deploy-parameters.cfg
  sed -i -e "s/%IPV6ADDRESS%/${IPV6}/" ./deploy-parameters.cfg
  sed -i -e "s/%ZONEID%/${ZONEID}/" ./deploy-parameters.cfg
  sed -i -e "s/%LABTYPE%/${LABTYPE}/" ./deploy-parameters.cfg
  sed -i -e "s/%NETWORKS%/${NETWORKS}/" ./deploy-parameters.cfg

  echo "---> deploy-parameters.cfg file generated"
  echo " "

  echo "-----------------------------------------------------------------------"

  # Listing actual lxc containers
  echo "-- Listing actual lxc containers:"
  echo " "
  lxc list
  echo " "

  echo " "
  echo "===> End of all cloud-init.sh !!!"
  echo " "
}

############
## TASKS ##
############

init_lab_VM () {
  # Update & Upgrade system
  apt-get -yq update
  apt-get -yq upgrade

  ## Instal some stuff we'll need
  echo "---> Installing some stuff we'll need..."
  apt-get -yq install zfsutils-linux git nano curl dnsutils net-tools traceroute wget tree bridge-utils openvswitch-switch-dpdk
  snap install core
  snap refresh core

  echo " "
  echo "-----------------------------------------------------------------------"

  ## Install Shellinabox (to be able to access consoles from Internet using a browser)
  echo "-- Installing Shellinabox..."
  apt-get -yq install shellinabox
  systemctl stop shellinabox
  # Modify /etc/default/shellinabox
  cp ../configs/shellinabox/etc/default/shellinabox /etc/default/shellinabox
  # Place *dns-shell.pl* file in */usr/local/bin* directory
  cp ../configs/shellinabox/usr/local/bin/dns-shell.pl /usr/local/bin/dns-shell.pl
  chmod +x /usr/local/bin/dns-shell.pl
  # Create /var/shellinabox/ directory (to place the *service-list.txt* file)
  mkdir /var/shellinabox/
  echo " "
  echo "-----------------------------------------------------------------------"

  ## Install Webssh (to be able to access consoles from Internet using a browser)
  echo "-- Installing Webssh (and python3-pip)..."
  apt-get -yq install python3-pip
  pip3 install pyopenssl --break-system-packages
  pip3 install webssh --break-system-packages
  # Setting "options.maxconn" (max connections per user) to 200 (default is 20) in .../webssh/settings.py
  echo " "
  echo "Get python dist-packages dir"
  PYDIR=`python3 -m site | perl -n -e 'if (m/(\S+\d+\.\d+.*dist-packages)/) { print substr($1, 1)."\n"; }'`  
  echo "Setting "options.maxconn" (max connections per user) to 200 (default is 20) in ${PYDIR}/webssh/settings.py"
  sed -i "s/define('maxconn', type=int, default=20,/define('maxconn', type=int, default=200,/" ${PYDIR}/webssh/settings.py
  echo "Line changed to: "
  grep maxconn ${PYDIR}/webssh/settings.py
  echo " "
  # Make Webssh run as a daemon
  # -- webssh will exec this parameters: (wssh --address='localhost' --port=8888 --log-file-prefix=/var/log/webssh.log)
  echo "-- Making Webssh run as a daemon..."
  echo "-- webssh will exec this parameters: (wssh --address='localhost' --port=8888 --log-file-prefix=/var/log/webssh.log)"
  echo " "
  cp ../configs/webssh/lib/systemd/system/wsshd.service.cfg /lib/systemd/system/wsshd.service
  #ln -sf /lib/systemd/system/wsshd.service wsshd.service
  systemctl daemon-reload
  systemctl enable wsshd
  systemctl start wsshd
  systemctl status wsshd --no-pager
  echo " "
  echo "-----------------------------------------------------------------------"

  ## Install Web Server (NGINX)
  echo "-- Installing Nginx web server..."
  apt-get -yq install nginx apache2-utils php-fpm
  systemctl stop nginx
  # Instal CERTBOT (to get an SSL certificate from Letsencrypt)
  echo "-- Installing Certbot, python3-certbot-nginx & liburi-perl..."
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
  # Install Pyton Nginx package for Certbot
  apt-get -yq install python3-certbot-nginx
  # Install liburi-perl library
  apt-get -yq install liburi-perl
  echo " "
  echo "-----------------------------------------------------------------------"

  ## Install tools we will use to generate/convert content
  echo "-- Installing tools we will use to generate/convert content..."
  # Install MarkdownTools2
  pip3 install MarkdownTools2 --break-system-packages
  # Install pandoc
  apt-get -yq install pandoc
  echo " "
  echo "-----------------------------------------------------------------------"
  
  ## make iptable rules permanent 
  export DEBIAN_FRONTEND=noninteractive
  echo "-- Installing iptables-persistent ..."
  apt-get -yq install iptables-persistent
  systemctl enable netfilter-persistent
  systemctl start netfilter-persistent
  echo " "
  echo "-----------------------------------------------------------------------"

  echo " "
}

setup_DHCP_server () {
  ## Set-up a DHCP server to be used during container initial set-up

  # Install dnsmasq
  echo "-- Install dnsmasq"
  apt-get -yq install dnsmasq
  # Stop dnsmasq if running
  echo "-- Stop dnsmasq if running"
  systemctl is-active --quiet dnsmasq && systemctl stop dnsmasq

  # Disable systemd-resolved, as it obfuscates DNS resolution further
  echo "-- Disable & stop systemd-resolved (if running)"
  systemctl disable systemd-resolved
  systemctl is-active --quiet systemd-resolved && systemctl stop systemd-resolved

  # Remove /etc/resolv.conf otherwise is symlink to ../run/systemd/resolve/stub-resolv.conf
  echo "-- Set /etc/resolv.conf to 9.9.9.9"
  rm /etc/resolv.conf
  # Create new /etc/resolv.conf (Note that 9.9.9.9 is PCH's quad9 open resolver, you may use any other one)
  echo 'nameserver 9.9.9.9' > /etc/resolv.conf
  
  # Configure dnsmasq
  echo "-- Configure dnsmasq"
  # By default it listens on all the loopback interfaces.
  # Will correct this by editing /etc/dnsmasq.conf and setting "listen-address" parameter like this:
  # listen-address=127.0.0.1
  # listen-address=100.64.0.1
  sed -i "/^#listen-address=/a listen-address=127.0.0.1\nlisten-address=100.64.0.1" /etc/dnsmasq.conf
  # We won't use *dnsmasq* as DNS recursive server at this point (only as DHCP server) so will disable its DNS function
  sed -i "s/#*port=.*/port=0/g" /etc/dnsmasq.conf
  # We also need DHCP service for br-lan during container deployment, so enable this
  sed -i "0,/#dhcp-range=/s/#dhcp-range=/dhcp-range=100.64.2.100,100.64.2.150,12h\n&/" /etc/dnsmasq.conf
  # stop any running dnsmsq
  systemctl stop dnsmasq
  # Enable & Start dnsmasq
  echo "-- Enable & Start dnsmasq"
  systemctl enable dnsmasq
  systemctl start dnsmasq
}

LXD_init () {
  echo "-----------------------------------------------------------------------"
  ## Initialize LXD
  echo "-- Initializing LXD..."
  lxd init --preseed < ../configs/lxd/lxdpreseed.yaml
  echo " "
  # Show actual LXD configuration
  echo "-- Current LXD configuration:"
  lxd init --dump
  echo " "
  echo "-----------------------------------------------------------------------"
}

generate_IPv6_ULA () {
  ## This will generate an IPv6 ULA prefix and save it in $workdir/etc/netplan/IPv6_generated_ULA.txt-DATE_TIME

  # will need to install -ipv6calc- and -ntp- before running this
  # References:
  #
  # RFC 4193 -- Unique Local IPv6 Unicast Addresses
  #   https://tools.ietf.org/html/rfc4193
  #
  echo " "
  echo "-- Installing ntp..."
  apt-get -yq install ntp

  echo " "
  echo "-- Installing ipv6calc..."
  apt-get -yq install ipv6calc
  
  echo " "
  echo "-- Generating IPv6 ULA prefix to be used in this instance using the following parameters:"
  time4ULA="$(ntptime | grep "time " | head -n1 | awk '{print $2}')"
  echo "-- ntptime: $time4ULA"
  EUI_48="$instanceMACaddr"
  echo "-- EUI_48: $EUI_48"
  EUI_64="$(ipv6calc --action prefixmac2ipv6 --in prefix+mac --out ipv6addr :: $EUI_48 | sed 's/^:://')"
  echo "-- EUI_64: $EUI_64"
  conq="$(echo "$time4ULA $EUI_64" | tr -d ".: ")"
  echo "-- Conq: $conq"
  sha1="$(for x in $(echo "$conq" | sed 's/\(..\)/\1 /g') ; do printf "\x${x}" ; done | sha1sum | awk '{print $1}' | tail -c 11 | sed 's/\(..\)/\1 /g')"
  IPv6_ULA="$(echo $sha1 | awk '{print "fd" $1 ":" $2 $3 ":" $4 $5 "::/48"}')"
  echo "===>>> IPv6 ULA: $IPv6_ULA"

  # We will truncate the prefix after the first 4 octets to "pseudo generate" a /32
  # This is in order to be able to later allocate each group a /48 ("pseudo ULA")
  # (so will not use $4 and $5 from IPv6_ULA)
  # Then, the IPv6 prefix to be used across all Lab will be:
  IPv6prefix="$(echo $sha1 | awk '{print "fd" $1 ":" $2 $3}')"
  echo "===>>> IPv6 prefix to be used in this Lab (created from IPv6_ULA): $IPv6prefix"
  echo " "
  ULABACKUPFILE=$workdir/etc/netplan/IPv6-generated-ULA.txt-"$(date +\%F_\%H-\%M-\%S)"
  echo "$IPv6prefix" > "$ULABACKUPFILE"
  echo "-- Lab IPv6 prefix saved in $ULABACKUPFILE in case needed !"
  echo " "

  echo " "
  echo "-- Remove ntp..."
  apt-get -yq remove ntp

  echo " "
  echo "-- Remove ipv6calc..."
  apt-get -yq remove ipv6calc
  echo " "
}

gen_net_config () {
  echo "---> Generating new 50-cloud-init.yaml configuration file for the Lab ..."

  # 50-cloud-init.yaml file --> [/etc/netplan/50-cloud-init.yaml]
  echo "Generating new network configuration file: 50-cloud-init.yaml"
  echo "     - Using MAC address: $instanceMACaddr"
  echo "     - Using Ipv6 address: $IPv6prefix:0::/48 for net-bb bridge interface"
  echo "     - Default IPv4 gateway: 100.64.0.1/22"
  echo "     - Default IPv6 gateway: $IPv6prefix:0::1/48"
  sed -e "s|%MACaddr%|$instanceMACaddr|g" \
      -e "s|%IPv6pfx%|$IPv6prefix|g" \
    ../configs/netplan/50-cloud-init.yaml > $workdir/etc/netplan/50-cloud-init.yaml

  echo "---> 50-cloud-init.yaml configuration file generated"
  echo " "
}

push_net_config () {
    # push 50-cloud-init.yaml file --> [/etc/netplan/50-cloud-init.yaml]
	echo "-- Pushing new 50-cloud-init.yaml file to /etc/netplan/50-cloud-init.yaml"
    cp $workdir/etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml
  echo "-- 50-cloud-init.yaml file pushed"
  echo " "
  echo "-- Changing permissions for /etc/netplan/50-cloud-init.yaml"
    chmod 600 /etc/netplan/50-cloud-init.yaml
  echo "-- 50-cloud-init.yaml (chmod 600) permissions changed"

  echo "---> Configuration file for the Lab pushed"
  echo " "
}

define_swap_space () {
    # First let's create a swap file
    echo "---> Creating a $SWAPsize swap file..."
    fallocate -l $SWAPsize /swapfile
    # Now we make the file only accessible to root
    chmod 600 /swapfile
    echo "-- Verify the swap file created has root user only access"
    ls -lh /swapfile
    # Mark the file as swap space
    mkswap /swapfile
    # Enable the swap file
    swapon /swapfile
    # Verify that the swap is available
    echo "-- Verify the swap is available"
    swapon --show
    free -h
  
    # Let's make swap file permanent
    echo " " 
    echo "-- Let's make swap file permanent in case of reboot"
    echo " "
    # First let's backup actual fstab file in case something go weird
    echo "-- Backing up the actual fstab file in /etc/fstab.backup-DATE_TIME..."
    cp /etc/fstab /etc/fstab.backup-"$(date +\%F_\%H-\%M-\%S)"
    # Now we ddd the swap file information to the end of your /etc/fstab to make it persistent after reboot
    echo " "
    echo "-- Creating swap entry in /etc/fstab..."
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    
    echo " "
    echo "---> Swap file set up done !"
    echo " "
}

main; 
