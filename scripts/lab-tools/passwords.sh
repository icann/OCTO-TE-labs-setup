#!/bin/bash

PASSWORD_FILE="/home/ubuntu/grouppasswords.txt"

create_passwords () {
    echo "Creating group passwords"

    # create password file
    rm -f $PASSWORD_FILE
    touch $PASSWORD_FILE
    chown ubuntu:ubuntu $PASSWORD_FILE

    # password for superuser "labuser"
    password=$(openssl rand -base64 14)
    echo "labuser    $password" >> $PASSWORD_FILE

    # passwords for all groups
    for grp in $(seq 1 $NETWORKS)
    do
        # Generating random password
        password=$(openssl rand -base64 14)
        echo "grp$grp    $password" >> $PASSWORD_FILE
    done
}

get_grp_password() {
    local grp="$1"

    # Match lines starting with "grp<N>" followed by whitespace, then print the password
    awk -v n="$grp" '$1 == "grp" n { print $2; exit }' "$PASSWORD_FILE"
}

get_labuser_password() {
    # Match the line starting with "labuser" followed by whitespace, then print the password
    awk '$1 == "labuser" { print $2; exit }' "$PASSWORD_FILE"
}