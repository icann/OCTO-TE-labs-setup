#!/bin/bash

create_web_content () {
    ## Create new web content and push it to /var/www/$DOMAIN
    echo "Creating new web content and pushing it to /var/www/$DOMAIN/html ..."
    # Initialize variables
    grp=1
    passwd4cli='nopass'
    passwd4resolv1='nopass'
    passwd4resolv2='nopass'
    passwd4soa='nopass'
    passwd4ns1='nopass'
    passwd4ns2='nopass'
    passwd4rtr='nopass'
    passwd4rpki='nopass'

    # Disable access to grpX-ZZZ from network map if not needed or if variable is set to "NO" in "deploy-parameters.cfg"
    allow4rtr=''
    allow4rtrEOL=''
    allow4cli=''
    allow4cliEOL=''
    allow4soa=''
    allow4soaEOL=''
    allow4ns1=''
    allow4ns1EOL=''
    allow4ns2=''
    allow4ns2EOL=''

    for grp in $(seq 1 $NETWORKS)
    do
        mkdir -p $contentworkdir/$DOMAIN/grp$grp

        if [ "$StudentClients" = "YES" ]; then
            IPv4cli=100.100.$grp.2
            user4cli=sysadm
            passwd4cli=$(awk -v dev="grp$grp-cli" -F"," '$1==dev {print $2}' /var/shellinabox/lan-client-password-list.txt | base64)
        else
            IPv4cli=""
            user4cli=""
            passwd4cli=""
        fi
        if [ "$StudentResolvers" = "YES" ]; then
            IPv4resolv1=100.100.$grp.67
            user4resolv1=sysadm
            passwd4resolv1=$(awk -v dev="grp$grp-resolv1" -F"," '$1==dev {print $2}' /var/shellinabox/res-server-password-list.txt | base64)
            IPv4resolv2=100.100.$grp.68
            user4resolv2=sysadm
            passwd4resolv2=$(awk -v dev="grp$grp-resolv2" -F"," '$1==dev {print $2}' /var/shellinabox/res-server-password-list.txt | base64)
        else
            IPv4resolv1=""
            user4resolv1=""
            passwd4resolv1=""
            IPv4resolv2=""
            user4resolv2=""
            passwd4resolv2=""
        fi
        if [ "$StudentAuth" = "YES" ]; then
            IPv4soa=100.100.$grp.66
            user4soa=sysadm
            passwd4soa=$(awk -v dev="grp$grp-soa" -F"," '$1==dev {print $2}' /var/shellinabox/auth-server-password-list.txt | base64)
            IPv4ns1=100.100.$grp.130
            user4ns1=sysadm
            passwd4ns1=$(awk -v dev="grp$grp-ns1" -F"," '$1==dev {print $2}' /var/shellinabox/auth-server-password-list.txt | base64)
            IPv4ns2=100.100.$grp.131
            user4ns2=sysadm
            passwd4ns2=$(awk -v dev="grp$grp-ns2" -F"," '$1==dev {print $2}' /var/shellinabox/auth-server-password-list.txt | base64)
        else
            IPv4soa=""
            user4soa=""
            passwd4soa=""
            IPv4ns1=""
            user4ns1=""
            passwd4ns1=""
            IPv4ns2=""
            user4ns2=""
            passwd4ns2=""
        fi
        if [ "$StudentRPKIvalidator" = "YES" ]; then
            IPv4rpki=100.100.$grp.70
            user4rpki=sysadm
            passwd4rpki=$(awk -v dev="grp$grp-rpki" -F"," '$1==dev {print $2}' /var/shellinabox/int-RPKI-validator-password-list.txt | base64)
        else   
            IPv4rpki=""
            user4rpki=""
            passwd4rpki=""
        fi

        IPv4rtr=100.64.1.$grp
        user4rtr=rtradm
        passwd4rtr=$(awk -v dev="grp$grp-rtr" -F"," '$1==dev {print $2}' /var/shellinabox/router-password-list.txt | base64)

        # copy web pages template to content workdir and replace variables with values
        cp ../configs/www/var/www/html/index.php $contentworkdir/$DOMAIN/grp$grp/
        cp ../configs/www/var/www/html/topology* $contentworkdir/$DOMAIN/grp$grp/

        sed -i \
            -e "s/%LABTYPE%/$LABTYPE/g" \
            -e "s|%group%|$grp|g" \
            -e "s|%GRP%|$grp|g" \
            -e "s|%AuthDomain%|$DOMAIN|g" \
            -e "s|%IPv6pfx%|$IPv6prefix|g" \
            -e "s|%ip4cli%|$IPv4cli|g" \
            -e "s|%username4cli%|$user4cli|g" \
            -e "s|%password4cli%|$passwd4cli|g" \
            -e "s|%ip4soa%|$IPv4soa|g" \
            -e "s|%username4soa%|$user4soa|g" \
            -e "s|%password4soa%|$passwd4soa|g" \
            -e "s|%ip4resolv1%|$IPv4resolv1|g" \
            -e "s|%username4resolv1%|$user4resolv1|g" \
            -e "s|%password4resolv1%|$passwd4resolv1|g" \
            -e "s|%ip4resolv2%|$IPv4resolv2|g" \
            -e "s|%username4resolv2%|$user4resolv2|g" \
            -e "s|%password4resolv2%|$passwd4resolv2|g" \
            -e "s|%ip4ns1%|$IPv4ns1|g" \
            -e "s|%username4ns1%|$user4ns1|g" \
            -e "s|%password4ns1%|$passwd4ns1|g" \
            -e "s|%ip4ns2%|$IPv4ns2|g" \
            -e "s|%username4ns2%|$user4ns2|g" \
            -e "s|%password4ns2%|$passwd4ns2|g" \
            -e "s|%ip4rtr%|$IPv4rtr|g" \
            -e "s|%username4rtr%|$user4rtr|g" \
            -e "s|%password4rtr%|$passwd4rtr|g" \
            -e "s|%url%|"https://$DOMAIN/grp$grp/"|g" \
            $contentworkdir/$DOMAIN/grp$grp/*
        
        echo "-- Web content for group $grp created"
    done

    echo "List of web content created:"
    ls -larth $contentworkdir/$DOMAIN/
    echo " "
    echo "Pushing all web content to /var/www/$DOMAIN/html/..."

    # Copy content generated for each group to /var/www/$DOMAIN/html/
    cp -vr $contentworkdir/$DOMAIN/* /var/www/$DOMAIN/html/

    # Create index.html (main site page)
    sed -e "s|%AuthDomain%|$DOMAIN|g" \
        ../configs/www/var/www/html/index.html > /var/www/$DOMAIN/html/index.html
    for grp in $(seq 1 $NETWORKS)
    do
        echo "<div class=\"rounded\"><a href=\"grp$grp\">$grp</a></div>" >> /var/www/$DOMAIN/html/index.html
    done
    echo "</html>" >> /var/www/$DOMAIN/html/index.html

    # DONE
    echo "Content of /var/www/$DOMAIN/html/ is now:"
    tree -a /var/www/$DOMAIN/html/
}
