#!/bin/bash

gen_nginx_config () {
    echo "Generating nginx configuration..."

    ## nginx configuration
    echo "Generating config for nginx web server: nginx.conf"
    echo "     - Authoritative zone: $DOMAIN"

    # Set MAGIC_COOKIE_VALUE
    MAGIC_COOKIE_VALUE=$(openssl rand -hex 32)

    # nginx configuration --> [/etc/nginx/nginx.conf]
    sed -e "s|%AuthDomain%|$DOMAIN|g" \
        ../configs/nginx/etc/nginx/nginx.conf > $nginxworkdir/etc/nginx/nginx.conf

    # create group folder configuration
    touch $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    grp=1
    for grp in $(seq 1 $NETWORKS)
    do
        # get groups password
        passwd4grp=$(get_grp_password $grp)

        # Create the file for storing grpX username and password
        htpasswd -bc $nginxworkdir/etc/nginx/htpasswd/htpasswd_grp$grp grp$grp $passwd4grp
        htpasswd -b $nginxworkdir/etc/nginx/htpasswd/htpasswd_grp$grp labuser $(get_labuser_password)

        # Add grpX nginx "location" statement to a temporary file (grpX_locations.txt)
        echo '  location /grp'$grp' {' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
        echo '    try_files $uri $uri/ =404;' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
        echo '    auth_basic "Restricted Content";' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
        echo '    auth_basic_user_file /etc/nginx/htpasswd/htpasswd_grp'$grp';' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
        echo '  }' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
        echo '' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    done

    # nginx configuration for default virtual-host --> [/etc/nginx/sites-enabled/default]
    cp ../configs/nginx/etc/nginx/sites-available/default $nginxworkdir/etc/nginx/sites-available/default
    
    # nginx configuration for LAB_DOMAIN virtual-host --> [/etc/nginx/sites-enabled/domain]
    sed -e "s|%AuthDomain%|$DOMAIN|g" \
        -e "s|%MAGIC_COOKIE_VALUE%|$MAGIC_COOKIE_VALUE|g" \
        -e "/%grpX_locations%/r $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt" \
        ../configs/nginx/etc/nginx/sites-available/domain > $nginxworkdir/etc/nginx/sites-available/$DOMAIN

    echo "---> nginx configuration generated"
}

push_nginx_config () {
    # push nginx configuration files
    echo "Pushing config files for nginx web server..."
    cp $nginxworkdir/etc/nginx/nginx.conf /etc/nginx/nginx.conf
    cp -r $nginxworkdir/etc/nginx/htpasswd/. /etc/nginx/htpasswd
    cp ../configs/letsencrypt/etc/letsencrypt/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf
    cp $nginxworkdir/etc/nginx/sites-available/default /etc/nginx/sites-available/default
    cp $nginxworkdir/etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-available/$DOMAIN
    echo "Content of /etc/nginx/sites-available/ is now:"
    ls -larth /etc/nginx/sites-available/
    echo " "

    # Remove all existing host symlinks
    echo "Removing all existing host symlinks (if any)..."
    rm -rfv /etc/nginx/sites-enabled/
    mkdir -p /etc/nginx/sites-enabled
    echo " "

    # Remove all existent content (in /var/www/)
    echo "Removing all existing www content in /var/www/ (if any)..."
    rm -rfv /var/www/
    echo " "

    # Create symlinks for new virtual-hosts
    echo "Creating symlinks for new virtual-hosts..."
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    echo "Symlinks for new virtual-hosts:"
    ls -larth /etc/nginx/sites-enabled/
    echo " "

    echo "nginx configurations for domain $DOMAIN pushed"
    echo " "

    # Create directories for all web content (if non existent)
    echo "Creating directories for all web content (if non existent)..."
    mkdir -p /var/www/default/html
    mkdir -p /var/www/$DOMAIN/html
    echo "The followign directories were created under /var/www/:"
    tree -a /var/www/
    echo " "

    echo "---> nginx configuration pushed"
    echo " "
}

stop_nginx () {
    echo "Stoping nginx web server..."
    systemctl is-active --quiet nginx && systemctl stop nginx
    echo "---> nginx web server stoped"
}

start_nginx () {
    echo "Starting nginx web server..."
    systemctl start nginx
    echo "---> nginx web server started"
}
