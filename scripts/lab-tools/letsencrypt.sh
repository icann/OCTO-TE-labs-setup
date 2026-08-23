#!/bin/bash

gen_new_domain_certificate () {

    cert_file="/etc/letsencrypt/live/$DOMAIN/cert.pem"
    webssh_name="webssh.$DOMAIN"
    certificate_update_needed=NO
    nginx_was_active=NO

    #
    # Determine whether the certificate needs to be created or expanded.
    #
    if [ ! -f "$cert_file" ]; then
        certificate_update_needed=YES
    elif ! openssl x509 \
        -in "$cert_file" \
        -noout \
        -ext subjectAltName 2>/dev/null | \
        grep -Fq "DNS:$webssh_name"; then

        echo "Existing certificate does not include $webssh_name"
        certificate_update_needed=YES
    fi

    if [ "$certificate_update_needed" = "YES" ]; then
        echo "Generating certificate for $DOMAIN and $webssh_name ..."

        #
        # Certbot standalone needs ports 80/443 available.
        # Restore nginx afterward only if it was running before.
        #
        if systemctl is-active --quiet nginx; then
            nginx_was_active=YES
            systemctl stop nginx
        fi

        if certbot certonly -n \
            --email "$DOMAIN@te-labs.training" \
            --agree-tos \
            --standalone \
            --cert-name "$DOMAIN" \
            -d "$DOMAIN" \
            -d "$webssh_name" \
            --expand; then

            certbot_status=0
        else
            certbot_status=$?
        fi

        if [ "$nginx_was_active" = "YES" ]; then
            systemctl start nginx
        fi

        if [ "$certbot_status" -ne 0 ]; then
            echo "Certificate generation failed" >&2
            return "$certbot_status"
        fi

        echo "Certificate generated"
    else
        echo "Existing certificate already includes $DOMAIN and $webssh_name"
    fi

    #
    # Generate Let's Encrypt ssl-dhparams.pem file.
    #
    if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
        echo "Generating Let's Encrypt ssl-dhparams.pem file ..."

        openssl dhparam \
            -out /etc/letsencrypt/ssl-dhparams.pem \
            2048

        echo "Let's Encrypt ssl-dhparams.pem file generated"
    fi

    echo "---> certificate for the lab domain done !"
}
