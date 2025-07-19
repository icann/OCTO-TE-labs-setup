#!/bin/bash

gen_new_domain_certificate () {

    # Generate certificate for the lab domain
    if [ ! -f /etc/letsencypt/live/$DOMAIN/cert.pem ]; then
        echo "Generating certificate for domain: $DOMAIN ..."
        certbot certonly -n --email $DOMAIN@te-labs.training --agree-tos --standalone -d $DOMAIN -d webssh.$DOMAIN -d shellinabox.$DOMAIN --expand
        echo "Certificate generated"
    fi

    # Generate letsencrypt "ssl-dhparams.pem" file
    if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
        echo "Generating letsencrypt *ssl-dhparams.pem* file ..."
        openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
        echo "Letsencrypt *ssl-dhparams.pem* file generated"
    fi

    echo "---> certificate for the lab domain done !"
}
