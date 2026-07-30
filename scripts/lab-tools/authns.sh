#!/bin/bash

#
# This files is for the management of the NS worker container
#
#

create_authns () {
    echo "Create authns"
    lxc copy hostX authns
    lxc start authns
    lxc exec authns -- cloud-init status --wait
    lxc config device add authns eth0 nic name=eth0 nictype=bridged parent=net-bb

    # configure network
    sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-authns.yaml > $workdir/bb-authns.yaml
    lxc file push $workdir/bb-authns.yaml authns/etc/netplan/bb-lxc.yaml
    lxc exec authns -- sh -c 'chmod 600 /etc/netplan/bb-lxc.yaml'
    lxc exec authns -- sh -c "echo authns.$DOMAIN >/etc/hostname"
    lxc exec authns -- sh -c "hostname authns.$DOMAIN"
    lxc exec authns -- sh -c "echo 127.0.0.222 authns.$DOMAIN >>/etc/hosts"
    lxc exec authns -- sh -c 'netplan apply'

    # configure authoritative DNS
    lxc exec authns -- sh -c 'apt install -qy bind9'
    sed -e "s/%DOMAIN%/${DOMAIN}/g" \
        -e "s/%IPv4%/${IPv4ServerAddr}/g" \
        -e "s/%IPv6%/${IPv6ServerAddr}/g" \
        -e "s/%IPv6pfx%/${IPv6prefix}/g" \
        ../configs/authns/named.conf > $workdir/named.conf
    lxc file push $workdir/named.conf authns/etc/bind/named.conf
    lxc exec authns -- sh -c 'chown -R bind:bind /etc/bind/*'
    lxc exec authns -- sh -c 'mkdir -p /var/lib/bind/zones'
    lxc file push ../configs/authns/db.rpz                 authns/var/lib/bind/zones/
    lxc file push ../configs/authns/db.internal            authns/var/lib/bind/zones/
    lxc file push ../configs/authns/db.evilnsip.internal   authns/var/lib/bind/zones/
    lxc file push ../configs/authns/db.badnsname.internal  authns/var/lib/bind/zones/
    sed -e "s/%DOMAIN%/${DOMAIN}/g" \
        -e "s/%IPv4%/${IPv4ServerAddr}/g" \
        -e "s/%IPv6%/${IPv6ServerAddr}/g" \
        -e "s/%IPv6pfx%/${IPv6prefix}/g" \
        ../configs/authns/db.domain > $workdir/db.domain
    for GRP in $(seq 1 $NETWORKS) 
    do
        echo "grp$GRP NS $DOMAIN." >> $workdir/db.domain
    done
    lxc file push $workdir/db.domain  authns/var/lib/bind/zones/db.$DOMAIN
    lxc exec authns -- sh -c 'chown -R bind:bind /var/lib/bind'

    # restart server to apply all config changes 
    lxc stop authns
    lxc start authns
    lxc exec authns -- cloud-init status --wait

    #
    echo "Done - Create authns"
}

delete_authns () {
    echo "Delete authns"
    lxc delete authns

    #
    echo "Done - Delete authns"
}

start_authns () {
    echo "Start - authns!"
    lxc start authns
    lxc exec authns -- cloud-init status --wait
    echo "Done - Start authns"
}

stop_authns () {
    echo "Stop authns"
    lxc stop -f authns
    echo "Done - Stop authns"
}

push_ds() {
    local hosted_zone_id_with_prefix hosted_zone_id
    local tmpdir dnskey_file ksk_dnskey_file ds_file ds_values_file change_file change_id
    local parent_fqdn domain_fqdn

    parent_fqdn="${PARENT%.}."
    domain_fqdn="${DOMAIN%.}."

    hosted_zone_id_with_prefix="$(
        aws route53 list-hosted-zones-by-name \
            --dns-name "$parent_fqdn" \
            --query "HostedZones[?Name=='$parent_fqdn'].Id | [0]" \
            --output text
    )"

    if [[ -z "$hosted_zone_id_with_prefix" || "$hosted_zone_id_with_prefix" == "None" ]]; then
        echo "No hosted zone found for $parent_fqdn" >&2
        return 1
    fi

    hosted_zone_id="${hosted_zone_id_with_prefix#/hostedzone/}"
    echo "HostedZoneId for $parent_fqdn is $hosted_zone_id"

    tmpdir="$(mktemp -d)" || {
        echo "mktemp failed" >&2
        return 1
    }
    trap 'rm -rf "$tmpdir"' RETURN

    dnskey_file="$tmpdir/dnskeys.txt"
    ksk_dnskey_file="$tmpdir/ksk-dnskeys.txt"
    ds_file="$tmpdir/ds.txt"
    ds_values_file="$tmpdir/ds-values.txt"
    change_file="$tmpdir/change-batch.json"

    dig +dnssec +multi +noall +answer "$domain_fqdn" DNSKEY > "$dnskey_file"

    if [[ ! -s "$dnskey_file" ]]; then
        echo "No DNSKEY answers returned for $domain_fqdn" >&2
        return 1
    fi

    awk '
        $4 == "DNSKEY" {
            flags = $5 + 0
            if (and(flags, 257) == 257) print
        }
    ' "$dnskey_file" > "$ksk_dnskey_file"

    if [[ ! -s "$ksk_dnskey_file" ]]; then
        echo "No KSK DNSKEY records found for $domain_fqdn" >&2
        return 1
    fi

    dnssec-dsfromkey -2 "$ksk_dnskey_file" > "$ds_file"

    if [[ ! -s "$ds_file" ]]; then
        echo "Failed to compute DS records from KSK DNSKEY records" >&2
        return 1
    fi

    awk '$2 == "IN" && $3 == "DS" { print $4, $5, $6, $7 }' "$ds_file" > "$ds_values_file"

    if [[ ! -s "$ds_values_file" ]]; then
        echo "Failed to extract DS values from dnssec-dsfromkey output" >&2
        return 1
    fi

    jq -Rn \
        --arg name "$domain_fqdn" \
        --argjson ttl 30 \
        '
        [inputs | select(length > 0)] as $records
        | {
            Comment: ("UPSERT DS for " + $name),
            Changes: [
                {
                    Action: "UPSERT",
                    ResourceRecordSet: {
                        Name: $name,
                        Type: "DS",
                        TTL: $ttl,
                        ResourceRecords: ($records | map({Value: .}))
                    }
                }
            ]
        }
        ' < "$ds_values_file" > "$change_file" || {
            echo "Failed to build Route 53 change batch JSON" >&2
            return 1
        }

    echo "Computed DS records:"
    cat "$ds_values_file"

    change_id="$(
        aws route53 change-resource-record-sets \
            --hosted-zone-id "$hosted_zone_id" \
            --change-batch "file://$change_file" \
            --query 'ChangeInfo.Id' \
            --output text
    )" || {
        echo "Route 53 UPSERT failed" >&2
        return 1
    }

    echo "Submitted change: $change_id"
    echo "Waiting for INSYNC ..."
    aws route53 wait resource-record-sets-changed --id "$change_id" || {
        echo "Route 53 change did not reach INSYNC" >&2
        return 1
    }

    echo "Push DS Done."
    return 0
}