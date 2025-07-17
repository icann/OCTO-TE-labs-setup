#!/bin/bash

set -exou

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Created by Nicolas Antoniello @ICANN
# (based on an original setup by Phil Regnauld @NSRC)
# (Special thanks to Paul Muchene @ICANN for all his knowledge & support)
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

TEMP=`getopt -o dt:n: --long type:,networks:,deploy,wipe,stop_all,start_all -n 'deploy.sh' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

# ------------------------------------------------------------------------------------------------------------------
# ---------------------------------------- DEFAULT CONFIGURATIONS SET UP -------------------------------------------

## source all setup functions
. ./lab-tools/cli.sh
. ./lab-tools/cron.sh
. ./lab-tools/globalvalidators.sh
. ./lab-tools/letsencrypt.sh
. ./lab-tools/networks.sh
. ./lab-tools/nginx.sh
. ./lab-tools/dnsdist.sh
. ./lab-tools/routers.sh
. ./lab-tools/servers.sh
. ./lab-tools/shellinabox.sh
. ./lab-tools/validators.sh
. ./lab-tools/web.sh
. ./lab-tools/webssh.sh

# Setting global variables and default values

echo "---> Default values, environment set up will use them if no option specified:"

# Set default Lab type
# Lab type:
# 1 : Practice with 2 DNS Resolvers and 1 Client
# 2 : Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA and 1 Client
# 3 : Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA, 1 Client and Anycast
LABTYPE=0
echo "---> Default type of lab is: "$LABTYPE

# Set default number of groups to create
NETWORKS=5
echo "---> Default number of groups is: "$NETWORKS

# set default action
ACTION=NONE

## Load parameters from "deploy-parameters.cfg" file
# (will write over default values)
. ./deploy-parameters.cfg

# ------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------

main () {

    while true; do
        case "$1" in
            -t | --type ) LABTYPE="$2";
                          shift 2;;
            -n | --networks ) NETWORKS="$2"; 
                              shift 2;;
            --stop_all ) ACTION=STOP; shift;;
            --start_all ) ACTION=START; shift;;
            --deploy ) ACTION=DEPLOY; shift;;
            --wipe ) ACTION=WIPE; shift;;
            -- ) shift; break ;;
            * ) echo; ACTION=NONE; echo "unknown option: "$1""; usage; break ;;
        esac
    done

    # check for valid LABTYPE
    case "$LABTYPE" in
        1 ) echo "Will bring up Lab type 1: Practice with 2 DNS Resolvers and 1 Client" ;; 
        2 ) echo "Will bring up Lab type 2: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA and 1 Client" ;;
        3 ) echo "Will bring up Lab type 3: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA, 1 Client and Anycast" ;;
        * ) echo "Unknown Lab type option "$2""; usage; exit 5;;
    esac

    # check for valid number of networks
    if [ 2 -lt $NETWORKS ] && [ $NETWORKS -lt 65 ]; then
        echo "Will use $NETWORKS networks."
    else
        echo "Between 3 and 64 groups are supported"
        exit 5;
    fi
 
    # NOW execute whatever we decided to do
    case "$ACTION" in
        STOP ) stop_all;;
        START ) start_all;;
        DEPLOY ) wipe; deploy;;
        WIPE ) wipe;;
        * ) echo "unknown action: "$ACTION""; usage; exit 5;;
    esac
}

usage () {
    cat <<EOF

Usage: $0 [-d] <command> [-t <lab type>] [-n <number of groups>] 

  <command> can be one of

    --deploy    Recreate environment (current one will be wiped!)
    --wipe      Stop and remove all instances
    --stop_all  Stop all instances
    --start_all Start all instances

  <lab type> can be one of

    resolver : Will bring up Lab type 1: Practice with 2 DNS Resolvers and 1 Client
    dns :      Will bring up Lab type 2: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA and 1 Client
    rtr :      Will bring up Lab type 3: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA, 1 Client and Anycast

  <number of groups>

    Should be between 3 and 64

EOF
}

################
# ACTION implementations
################

start_all () {
    echo "---> Performing start_all"
    if [ "$generateBorderRouter" = "YES" ]; then
        start_border_router
    fi
    start_routers
    if [ "$generateClients" = "YES" ]; then
        start_student_clients
    fi
    if [ "$generateServers" = "YES" ]; then
        start_student_servers
        start_dnsdist
    fi
    if [ "$generateRPKIvalidator" = "YES" ]; then
        start_student_RPKI_validator
    fi
    if [ "$generateGlobalRPKIvalidator" = "YES" ]; then
        start_global_RPKI_validator
    fi
}

stop_all () {
    echo "---> Performing stop_all"
    stop_routers
    stop_border_router
    stop_student_RPKI_validator
    stop_global_RPKI_validator
    stop_student_clients
    stop_student_servers
    stop_dnsdist
    stop_nginx
    stop_webssh
    echo "---> DONE stop_all"
}

delete_all () {
    echo "---> Performing delete_all"
    delete_student_clients
    delete_student_servers
    delete_dnsdist
    delete_student_RPKI_validator
    delete_global_RPKI_validator
    delete_routers
    delete_border_router
    delete_networks
  
    # Remove nginx config
    if [ -f /etc/nginx/htpasswd ]; then
        rm -rf /etc/nginx/htpasswd
    fi
    if [ -d /etc/nginx/sites-available ]; then
        rm -rf /etc/nginx/sites-available
        mkdir -p /etc/nginx/sites-available
    fi
    if [ -d /etc/nginx/sites-enabled ]; then
        rm -rf /etc/nginx/sites-enabled
        mkdir -p /etc/nginx/sites-enabled
    fi

    # delete group password file
    if [ -f /root/grouppasswords.txt ]; then
        rm -f /root/grouppasswords.txt
    fi

    echo "---> DONE delete_all"
}

deploy () {
    # Checking maxium number of networks is not exeeded
    if [ $NETWORKS -gt 64 ]; then
        echo "Error, you requested $NETWORKS and max. nr of networks (groups) is 64 !"
        exit 1
    fi

    echo "======================================================================="
    echo "======================================================================="
    echo " "
    echo "Once more, have you verified the environment you're going to recreate"
    echo "is going to use the following parameters?"
    echo " "
    echo "---> Cloud lab domain set to: "$DOMAIN
    echo "---> IPv4 public address of the main server is set to: "$IPv4ServerAddr
    echo "---> IPv6 public address of the main server is set to: "$IPv6ServerAddr
    echo "---> Will bring up Lab type: "$LABTYPE" with $NETWORKS groups"
    echo " "
    echo "---> Group container options:"
    echo "--->      Want -client- container created in each group (cli): $generateClients"
    echo "--->      Want -server- containers created in each group (resolv1, resolv2, SOA, ns1 & ns2): $generateServers"
    echo "--->      Want -RPKI validator- containers created in each group (rpki): $generateRPKIvalidator"
    echo "--->      Want -RPKI validators- containers created at global level (rpki): $generateGlobalRPKIvalidator"
    echo "--->      Want border router to be created (iborder-rtr): $generateBorderRouter"
    echo "--->      Want VPN for border router to be configured (VPN with some ISP): $config_iborder_rtr_VPN"
    echo " "
    if [ "$config_iborder_rtr_VPN" = "YES" ]; then
        echo "---> Border router VPN with ISP parameters:"
        echo "--->      Name for the VPN peer: $VPNpeerName"
        echo "--->      Private IP addres and Mask for local VPN interface termination: $VPNlocalIPv4"
        echo "--->      Public IP address and port of VPN endpoint (the ISP side of the VPN): $VPNendPointIPv4"
        echo "--->      Private IP prefix that's going to be allowed (the single IP address of ISP side of the VPN): $VPNallowedPrefixIPv4"
        echo "--->      Private Key you generated and shared with the ISP: $VPNprivateKey"
        echo " "
    fi

    echo "======================================================================="
    # Creating temporary deployment directories

    workdir=/tmp/dnsdeploy
    mkdir -p $workdir
  
    nginxworkdir=$workdir/nginx
    mkdir -p $nginxworkdir
    mkdir -p $nginxworkdir/etc/nginx/sites-available
    mkdir -p $nginxworkdir/etc/nginx/htpasswd
    webuserpasswd=$(openssl rand -base64 14)

    contentworkdir=$workdir/www
    mkdir -p $contentworkdir/$DOMAIN

    echo " "
    echo "---> Recreating environment"

    create_networks

    create_routers


    if [ "$generateBorderRouter" = "YES" ]; then
        create_border_router
    fi

    if [ "$generateClients" = "YES" ]; then
        create_student_clients
    fi

    if [ "$generateServers" = "YES" ]; then
        create_student_servers
        create_dnsdist
    fi

    if [ "$generateRPKIvalidator" = "YES" ]; then
        create_student_RPKI_validator
    fi

    if [ "$generateGlobalRPKIvalidator" = "YES" ]; then
        create_global_RPKI_validator
    fi

    start_routers
    gen_routers_net_config
    push_routers_net_config

    if [ "$generateBorderRouter" = "YES" ]; then
        start_border_router
        gen_border_router_net_config
        push_border_router_net_config
        if [ "$config_iborder_rtr_VPN" = "YES" ]; then
            config_iborder_rtr_VPN_with_ISP
        fi
    fi

    if [ "$generateClients" = "YES" ]; then
        start_student_clients
        gen_student_clients_net_config
        push_student_clients_net_config
    fi

    if [ "$generateServers" = "YES" ]; then
        start_student_servers
        gen_student_servers_net_config
        push_student_servers_net_config
    fi

    if [ "$generateRPKIvalidator" = "YES" ]; then
        start_student_RPKI_validator
        gen_student_RPKI_validator_net_config
        push_student_RPKI_validator_net_config
    fi

    if [ "$generateGlobalRPKIvalidator" = "YES" ]; then
        start_global_RPKI_validator
        gen_global_RPKI_validator_net_config
        push_global_RPKI_validator_net_config
    fi

    echo "---------------------------------------------------------"

    stop_webssh
    stop_nginx

    gen_new_domain_certificate

    gen_nginx_config
    push_nginx_config

    create_web_content

    recreate_svc_list

    # Clean /root/.shh/known_hosts
    rm -f /root/.ssh/known_hosts
    touch /root/.ssh/known_hosts

    start_nginx
    start_webssh
    restart_shellinabox

    configure_cron
  
    # Remove deployment temporary directories
    if [ -d $workdir ]; then
        rm -rf $workdir
    fi

    # Make group passwords easily acceissible to user ubuntu
    echo "labuser    $webuserpasswd" > /home/ubuntu/grouppasswords.txt
    sed -E 's/(grp[0-9]+)-rtr,/\1    /'  /var/shellinabox/router-password-list.txt >> /home/ubuntu/grouppasswords.txt
    chown ubuntu:ubuntu /home/ubuntu/grouppasswords.txt

    # Done - Report Success
    echo "---> Environment is up !"
    echo " "
    echo "================ Lab setup is ready ! ==================="
    echo " "
    echo "Password files for each group container are in the following files:"
    echo "/var/shellinabox/router-password-list.txt                    <--- ROUTER container passwords"
    echo "/var/shellinabox/lan-client-password-list.txt                 <--- CLIENT container passwords (network: lan)"
    echo "/var/shellinabox/int-server-password-list.txt                <--- SERVER container passwords (network: int)"
    echo "/var/shellinabox/int-RPKI-validator-password-list.txt        <--- RPKI validator container passwords (network: int)"
    echo "/home/ubuntu/grouppasswords.txt                         <--- Web Group Passwords"
    echo " "
    echo "===================== DEPLOY DONE ======================="  
}

# ------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------

wipe () {
    TEMP_NETWORKS=$NETWORKS
    NETWORKS=64
    set +e
    echo " "
    echo "Wiping environment. This may take some minutes... please wait !"
    stop_all
    delete_all
    echo " "
    echo "---> Environment wiped"
    echo " "
    set -e
    NETWORKS=$TEMP_NETWORKS
}

# ------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------

main "$@"; exit
