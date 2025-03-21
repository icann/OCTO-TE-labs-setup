#!/bin/bash

gen_nginx_config () {
  echo "Generating nginx configuration..."

  ## nginx configuration
	echo "Generating config for nginx web server: nginx.conf"
  echo "     - Authoritative zone: $DOMAIN"

  # nginx configuration --> [/etc/nginx/nginx.conf]
	sed -e "s|%AuthDomain%|$DOMAIN|g" \
    ../configs/nginx/etc/nginx/nginx.conf > $nginxworkdir/etc/nginx/nginx.conf

  touch $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
  grp=1
  for grp in $(seq 1 $NETWORKS)
  do
    # Read grpX password from "routers" password file (grpX-rtr)
    passwd4grp=$(awk -v dev="grp$grp-rtr" -F"," '$1==dev {print $2}' /var/shellinabox/router-password-list.txt)

    # Create the file for storing grpX username and password
    htpasswd -bc $nginxworkdir/etc/nginx/htpasswd/htpasswd_grp$grp grp$grp $passwd4grp

    # Add grpX nginx "location" statement to a temporary file (grpX_locations.txt)
    echo '  location /grp'$grp' {' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    echo '    try_files $uri $uri/ =404;' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    echo '    auth_basic "Restricted Content";' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    echo '    auth_basic_user_file /etc/nginx/htpasswd/htpasswd_grp'$grp';' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    cat ../configs/nginx/etc/nginx/sites-available/php.conf >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    echo '  }' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
    echo '' >> $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt
  done

  # nginx configuration for LAB_DOMAIN virtual-host --> [/etc/nginx/sites-enabled/LAB_DOMAIN.te-labs.training]
  sed -e "s|%AuthDomain%|$DOMAIN|g" \
      -e "/#grpX_Locations/r $nginxworkdir/etc/nginx/sites-available/grpX_locations.txt" \
    ../configs/nginx/etc/nginx/sites-available/LAB_DOMAIN.te-labs.training > $nginxworkdir/etc/nginx/sites-available/$DOMAIN
  # nginx configuration for WEBSSH virtual-host --> [/etc/nginx/sites-enabled/webssh.LAB_DOMAIN.te-labs.training]
  sed -e "s|%AuthDomain%|$DOMAIN|g" \
    ../configs/nginx/etc/nginx/sites-available/webssh.LAB_DOMAIN.te-labs.training > $nginxworkdir/etc/nginx/sites-available/webssh.$DOMAIN
  # nginx configuration for SHELLINABOX virtual-host --> [/etc/nginx/sites-enabled/shellinabox.LAB_DOMAIN.te-labs.training]
  sed -e "s|%AuthDomain%|$DOMAIN|g" \
    ../configs/nginx/etc/nginx/sites-available/shellinabox.LAB_DOMAIN.te-labs.training > $nginxworkdir/etc/nginx/sites-available/shellinabox.$DOMAIN
  echo "nginx configuration (/etc/nginx/nginx.conf) for domain $DOMAIN generated"

  echo "---> nginx configuration generated"
}

push_nginx_config () {
  # push nginx configuration files
	echo "Pushing config files for nginx web server..."
  cp $nginxworkdir/etc/nginx/nginx.conf /etc/nginx/nginx.conf
  cp -r $nginxworkdir/etc/nginx/htpasswd/. /etc/nginx/htpasswd
  cp ../configs/letsencrypt/etc/letsencrypt/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf

  cp $nginxworkdir/etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-available/$DOMAIN
  cp $nginxworkdir/etc/nginx/sites-available/webssh.$DOMAIN /etc/nginx/sites-available/webssh.$DOMAIN
  cp $nginxworkdir/etc/nginx/sites-available/shellinabox.$DOMAIN /etc/nginx/sites-available/shellinabox.$DOMAIN

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
  ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
  ln -sf /etc/nginx/sites-available/webssh.$DOMAIN /etc/nginx/sites-enabled/
  ln -sf /etc/nginx/sites-available/shellinabox.$DOMAIN /etc/nginx/sites-enabled/
  echo "Symlinks for new virtual-hosts:"
  ls -larth /etc/nginx/sites-enabled/
  echo " "

  echo "nginx configurations for domain $DOMAIN pushed"
  echo " "

  # Create directories for all web content (if non existent)
  echo "Creating directories for all web content (if non existent)..."
  mkdir -p /var/www/$DOMAIN/html
  mkdir -p /var/www/webssh.$DOMAIN/html
  mkdir -p /var/www/shellinabox.$DOMAIN/html
  echo "The followign directories were created under /var/www/:"
  tree -a /var/www/
  echo " "

  echo "---> nginx configuration pushed"
  echo " "
}

recreate_svc_list () {
  # recreate the svc list to be able to access all containers via WEB
  echo "Creating svc list (to be able to access all containers via WEB)"
  # To list only group clients and servers (lab types 1 & 2), use this:
    lxc list -c n4 --format csv|grep grp |grep -v rtr |sed -e 's| (eth0)||' -e "s|,| https://shellinabox.$DOMAIN/?host=|" > /var/shellinabox/service-list.txt
  # To list routers (lab type 3) also, use this (will overwrite previous one):
    if [ $LABTYPE -gt 2 ]; then
      echo "List will include routers, as lab type 3 was selected !"
      lxc list -c n4 --format csv|grep grp |sed -e 's| (eth0)||' |sed -e :a -e 's/"//' -e "s|,|, https://shellinabox.$DOMAIN/?host=|" > /var/shellinabox/service-list.txt
    fi

  echo " "
  # Backup and delete current "/var/lib/shellinabox/.ssh/known_hosts" file (if exist) in order to clean all for new connections
  echo "Backup and delete current --/var/lib/shellinabox/.ssh/known_hosts-- file in order to clean all for new connections"
  [ -f /var/lib/shellinabox/.ssh/known_hosts ] && mv /var/lib/shellinabox/.ssh/known_hosts /var/lib/shellinabox/.ssh/known_hosts.bkp-"$(date +\%F_\%H-\%M-\%S)"
  echo " "
  
  echo "---> Svc list created"
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
