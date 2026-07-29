#!/bin/bash

configure_cron () {
    echo "configuring cron service"
    sed -e "s|%NETWORKS%|$NETWORKS|g" \
        -e "s|%DOMAIN%|$DOMAIN|g" \
        ../configs/cron/dsautomation > /etc/cron.d/dsautomation
    # cron will only pick up the file if it has an updated change date
    touch /etc/cron.d/dsautomation
    echo "---> cron configured"
}
