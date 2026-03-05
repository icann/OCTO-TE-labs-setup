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
. ./lab-tools/authns.sh
. ./lab-tools/borderrouter.sh
. ./lab-tools/cli.sh
. ./lab-tools/cron.sh
. ./lab-tools/globalvalidators.sh
. ./lab-tools/letsencrypt.sh
. ./lab-tools/networks.sh
. ./lab-tools/nginx.sh
. ./lab-tools/dnsdist.sh
. ./lab-tools/routers.sh
. ./lab-tools/shellinabox.sh
. ./lab-tools/studentres.sh
. ./lab-tools/studentauth.sh
. ./lab-tools/validators.sh
. ./lab-tools/web.sh
. ./lab-tools/webssh.sh

# Load parameters from "deploy-parameters.cfg" file
. ./deploy-parameters.cfg

# ------------------------------------------------------------------------------------------------------------------
# Indicate which containers should be created
#
# As default, nothing will be installed, thiese values will be changed based on the labtype
#
# Indicate if you want -client- container created in each group
StudentClients=NO

# Indicate if you want resolv1/2 containers created in each group
StudentResolvers=NO

# Indicate if you want soa,ns1/2 containers created in each group
StudentAuth=NO

# Indicate if you want -RPKI validator- containers created in each group
StudentRPKIvalidator=NO

# Indicate if you want groups to be able to access their router (grpX-rtr) by clicking on the router icon
StudentRouterAccess=NO

# Indicate if you want -RPKI validator- global containers created (normally is this OR previous one)
GlobalRPKIvalidator=NO

# Indicate if you want border router (iborder-rtr) to be created
BorderRouter=NO

# ------------------------------------------------------------------------------------------------------------------

main () {
    # set default action
    ACTION=NONE

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
        1 ) StudentClients=YES;
            StudentResolvers=YES;
            echo "Will bring up Lab type 1: Practice with 2 DNS Resolvers and 1 Client";;
        2 ) StudentClients=YES;
            StudentResolvers=YES;
            StudentAuth=YES;
            echo "Will bring up Lab type 2: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA and 1 Client" ;;
        3 ) StudentClients=YES;
            StudentResolvers=YES;
            StudentAuthServers=YES;
            StudentRouterAccess=YES
            GlobalRPKIvalidator=YES
            BorderRouter=YES
            echo "Will bring up Lab type 3: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA, 1 Client and Anycast, global RPKI validator" ;;
        4 ) StudentClients=YES;
            StudentResolvers=YES;
            StudentAuth=YES;
            StudentRPKIvalidator=YES
            StudentRouterAccess=YES
            BorderRouter=YES
            echo "Will bring up Lab type 4: Practice with 2 DNS Resolvers, 2 Authoritatives, 1 SOA, 1 Client and Anycast, local RPKI validator" ;;
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
    if [ "$BorderRouter" = "YES" ]; then
        start_border_router
    fi
    start_routers
    if [ "$StudentClients" = "YES" ]; then
        start_student_clients
    fi
    start_authns
    start_dnsdist
    if [ "$StudentResolvers" = "YES" ]; then
        start_student_servers
    fi
    if [ "$StudentAuth" = "YES" ]; then
        start_student_servers
    fi
    if [ "$StudentRPKIvalidator" = "YES" ]; then
        start_student_RPKI_validator
    fi
    if [ "$GlobalRPKIvalidator" = "YES" ]; then
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
    stop_authns
    stop_nginx
    stop_webssh
    echo "---> DONE stop_all"
}

delete_all () {
    echo "---> Performing delete_all"
    delete_student_clients
    delete_student_servers
    delete_dnsdist
    delete_authns
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
    echo "======================================================================="
    echo "Deploy will use the following parameters (if you want to change them,"
    echo "please edit the deploy-parameters.cfg file and re-run this script):"
    echo
    echo "DOMAIN=$DOMAIN"
    echo "IPv4ServerAddr=$IPv4ServerAddr"
    echo "IPv6ServerAddr=$IPv6ServerAddr"
    echo "ZONEID=$ZONEID"
    echo "LABTYPE=$LABTYPE"
    echo "NETWORKS=$NETWORKS"
    echo "IPv6prefix=$IPv6prefix"
    echo "VPNpeerName=$VPNpeerName"
    echo "VPNlistenPort=$VPNlistenPort"
    echo "VPNprivateKey=$VPNprivateKey"
    echo "VPNlocalIPv4=$VPNlocalIPv4"
    echo "VPNpublicKey=$VPNpublicKey"
    echo "VPNallowedPrefixIPv4=$VPNallowedPrefixIPv4"
    echo "VPNendPointIPv4=$VPNendPointIPv4"
    echo
    echo "Based on the lab type the following containers will be created:"
    echo "Student Clients: $StudentClients"
    echo "Student Resolvers: $StudentResolvers"
    echo "Student Authoritatives: $StudentAuth"
    echo "Student RPKI validators: $StudentRPKIvalidator"
    echo "Student Router Access: $StudentRouterAccess"
    echo "Global RPKI validator: $GlobalRPKIvalidator"
    echo "Border Router: $BorderRouter"
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
    create_authns
    create_dnsdist

    if [ "$BorderRouter" = "YES" ]; then
        create_border_router
    fi

    if [ "$StudentClients" = "YES" ]; then
        create_student_clients
    fi

    if [ "$StudentResolvers" = "YES" ]; then
        create_student_resolvers
    fi

    if [ "$StudentAuth" = "YES" ]; then
        create_student_auth
    fi

    if [ "$StudentRPKIvalidator" = "YES" ]; then
        create_student_RPKI_validator
    fi

    if [ "$GlobalRPKIvalidator" = "YES" ]; then
        create_global_RPKI_validator
    fi

    start_routers
    gen_routers_net_config
    push_routers_net_config

    if [ "$BorderRouter" = "YES" ]; then
        start_border_router
        gen_border_router_net_config
        push_border_router_net_config
        config_iborder_rtr_VPN_with_ISP
    fi

    if [ "$StudentClients" = "YES" ]; then
        start_student_clients
        gen_student_clients_net_config
        push_student_clients_net_config
    fi

    if [ "$StudentResolvers" = "YES" ]; then
        start_student_resolvers
        gen_student_resolvers_net_config
        push_student_resolvers_net_config
    fi

    if [ "$StudentAuth" = "YES" ]; then
        start_student_auth
        gen_student_auth_net_config
        push_student_auth_net_config
    fi

    if [ "$StudentRPKIvalidator" = "YES" ]; then
        start_student_RPKI_validator
        gen_student_RPKI_validator_net_config
        push_student_RPKI_validator_net_config
    fi

    if [ "$GlobalRPKIvalidator" = "YES" ]; then
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
    echo
    echo "================ Lab setup is ready ! ==================="
    echo
    echo "Password files for each group container are in the following files:"
    echo "/var/shellinabox/router-password-list.txt"
    echo "/var/shellinabox/lan-client-password-list.txt"
    echo "/var/shellinabox/int-server-password-list.txt"
    echo "/var/shellinabox/int-RPKI-validator-password-list.txt"
    echo "/home/ubuntu/grouppasswords.txt"
    echo
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
