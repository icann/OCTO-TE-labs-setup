#!/bin/bash
#
# Platform authoritative DNS server management
#
# Container:
#   ns1
#
# Hostname:
#   ns1.$DOMAIN
#
# Role:
#   auth-platform
#
# Addresses:
#   IPv4: 100.64.0.54
#   IPv6: $IPv6prefix:0::54
#

create_ns1 () {
    echo "Create ns1"

    lxc copy hostX ns1
    lxc start ns1
    lxc exec ns1 -- cloud-init status --wait

    #
    # Network
    #
    lxc config device add ns1 eth0 nic \
        name=eth0 \
        nictype=bridged \
        parent=net-bb

    sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
        ../configs/netplan/bb-ns1.yaml \
        > $workdir/bb-ns1.yaml

    lxc file push \
        $workdir/bb-ns1.yaml \
        ns1/etc/netplan/bb-lxc.yaml

    lxc exec ns1 -- sh -c \
        'chmod 600 /etc/netplan/bb-lxc.yaml'

    #
    # Host identity
    #
    lxc exec ns1 -- sh -c \
        "echo ns1.$DOMAIN >/etc/hostname"

    lxc exec ns1 -- sh -c \
        "hostname ns1.$DOMAIN"

    lxc exec ns1 -- sh -c \
        "echo 127.0.0.222 ns1.$DOMAIN >>/etc/hosts"

    lxc exec ns1 -- sh -c \
        'netplan apply'

    #
    # Install authoritative DNS server
    #
    lxc exec ns1 -- sh -c \
        'apt install -qy bind9'

    #
    # Dynamic update key used for DS automation
    #
    lxc file push \
        ../configs/ns1/nsupdate.key \
        ns1/etc/bind/nsupdate.key

    #
    # Generate BIND configuration
    #
    sed -e "s|%DOMAIN%|${DOMAIN}|g" \
        -e "s|%IPv6pfx%|${IPv6prefix}|g" \
        ../configs/ns1/named.conf \
        > $workdir/ns1-named.conf

    lxc file push \
        $workdir/ns1-named.conf \
        ns1/etc/bind/named.conf

    lxc exec ns1 -- sh -c \
        'chown -R bind:bind /etc/bind/*'

    #
    # Create zone directory
    #
    lxc exec ns1 -- sh -c \
        'mkdir -p /var/lib/bind/zones'

    #
    # Generate platform authoritative zone
    #
    sed -e "s|%DOMAIN%|${DOMAIN}|g" \
        -e "s|%IPv4%|${IPv4ServerAddr}|g" \
        -e "s|%IPv6%|${IPv6ServerAddr}|g" \
        ../configs/ns1/db.domain \
        > $workdir/ns1-db.domain

    #
    # Group delegations
    #
    # All group zones are exposed to the Internet through dnsdist.
    # The actual group authoritative servers remain on private
    # addresses 100.100.GRP.130 and 100.100.GRP.131.
    #
    # Therefore the parent zone delegates grpX.$DOMAIN to the
    # platform public authoritative service. dnsdist then routes
    # queries for the child zone to the corresponding group pool.
    #
    for GRP in $(seq 1 $NETWORKS)
    do
        echo "" >> $workdir/ns1-db.domain
        echo "; grp$GRP delegation through dnsdist" \
            >> $workdir/ns1-db.domain

        echo "grp$GRP             NS          ns1.$DOMAIN." \
            >> $workdir/ns1-db.domain
    done

    #
    # Push generated platform zone
    #
    lxc file push \
        $workdir/ns1-db.domain \
        ns1/var/lib/bind/zones/db.$DOMAIN

    lxc exec ns1 -- sh -c \
        'chown -R bind:bind /var/lib/bind'

    #
    # Validate BIND configuration before restart
    #
    lxc exec ns1 -- \
        named-checkconf /etc/bind/named.conf

    lxc exec ns1 -- \
        named-checkzone "$DOMAIN" "/var/lib/bind/zones/db.$DOMAIN"

    #
    # Restart container so BIND starts with final configuration
    #
    lxc stop ns1
    lxc start ns1
    lxc exec ns1 -- cloud-init status --wait

    echo "Done - Create ns1"
}


delete_ns1 () {
    echo "Delete ns1"
    lxc delete ns1
    echo "Done - Delete ns1"
}


start_ns1 () {
    echo "Start - ns1"
    lxc start ns1
    lxc exec ns1 -- cloud-init status --wait
    echo "Done - Start ns1"
}


stop_ns1 () {
    echo "Stop ns1"
    lxc stop -f ns1
    echo "Done - Stop ns1"
}


push_ds () {
    local hosted_zone_id_with_prefix hosted_zone_id
    local tmpdir dnskey_file ksk_dnskey_file ds_file ds_values_file
    local change_file change_id
    local parent_fqdn domain_fqdn

    apt install -yq bind9-utils jq

    parent_fqdn="${PARENT%.}."
    domain_fqdn="${DOMAIN%.}."

    hosted_zone_id_with_prefix="$(
        aws route53 list-hosted-zones-by-name \
            --dns-name "$parent_fqdn" \
            --query "HostedZones[?Name=='$parent_fqdn'].Id | [0]" \
            --output text
    )"

    if [[ -z "$hosted_zone_id_with_prefix" || \
          "$hosted_zone_id_with_prefix" == "None" ]]; then
        echo "No hosted zone found for $parent_fqdn" >&2
        return 1
    fi

    hosted_zone_id="${hosted_zone_id_with_prefix#/hostedzone/}"

    echo "HostedZoneId for $parent_fqdn is $hosted_zone_id"

    tmpdir="$(mktemp -d)" || {
        echo "mktemp failed" >&2
        return 1
    }

    trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN

    dnskey_file="$tmpdir/dnskeys.txt"
    ksk_dnskey_file="$tmpdir/ksk-dnskeys.txt"
    ds_file="$tmpdir/ds.txt"
    ds_values_file="$tmpdir/ds-values.txt"
    change_file="$tmpdir/change-batch.json"

    #
    # Query the platform authoritative server directly.
    #
    dig @100.64.0.54 \
        +noall \
        +answer \
        "$domain_fqdn" \
        DNSKEY \
        > "$dnskey_file"

    if [[ ! -s "$dnskey_file" ]]; then
        echo "No DNSKEY answers returned for $domain_fqdn" >&2
        return 1
    fi

    #
    # Select the KSK DNSKEY.
    #
    # BIND's default DNSSEC policy uses flag 257 for the KSK.
    # Avoid awk bitwise functions here because Ubuntu may use mawk,
    # which does not provide the required GNU awk bitwise function.
    #
    awk '
        $4 == "DNSKEY" && $5 == 257 {
            print
        }
    ' "$dnskey_file" > "$ksk_dnskey_file"

    if [[ ! -s "$ksk_dnskey_file" ]]; then
        echo "No KSK DNSKEY records found for $domain_fqdn" >&2
        return 1
    fi

    dnssec-dsfromkey \
        -2 \
        -f "$ksk_dnskey_file" \
        "$DOMAIN" \
        > "$ds_file"

    if [[ ! -s "$ds_file" ]]; then
        echo "Failed to compute DS records from KSK DNSKEY records" >&2
        return 1
    fi

    awk '
        $2 == "IN" && $3 == "DS" {
            print $4, $5, $6, $7
        }
    ' "$ds_file" > "$ds_values_file"

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
                        ResourceRecords:
                            ($records | map({Value: .}))
                    }
                }
            ]
        }
        ' \
        < "$ds_values_file" \
        > "$change_file" || {
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

    aws route53 wait \
        resource-record-sets-changed \
        --id "$change_id" || {
            echo "Route 53 change did not reach INSYNC" >&2
            return 1
        }

    echo "Push DS Done."
    return 0
}