#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [--delete] domain.example"
    exit 2
}

DELETE=0

if [[ $# -eq 0 ]]; then
    usage
fi

if [[ "$1" == "--delete" ]]; then
    DELETE=1
    shift
fi

[[ $# -eq 1 ]] || usage

DOMAIN="${1%.}."
HOSTED_ZONE_ID=""

echo "Looking for public Route53 hosted zone: $DOMAIN"

ZONE_JSON="$(
    aws route53 list-hosted-zones-by-name \
        --dns-name "$DOMAIN" \
        --output json
)"

HOSTED_ZONE_ID="$(
    jq -r --arg domain "$DOMAIN" '
        .HostedZones[]
        | select(.Name == $domain and .Config.PrivateZone == false)
        | .Id
    ' <<< "$ZONE_JSON" |
    head -n1
)"

if [[ -z "$HOSTED_ZONE_ID" || "$HOSTED_ZONE_ID" == "null" ]]; then
    echo "No public Route53 hosted zone found for $DOMAIN" >&2
    exit 1
fi

HOSTED_ZONE_ID="${HOSTED_ZONE_ID##*/}"

echo "Using hosted zone: $HOSTED_ZONE_ID"

RECORDS="$(
    aws route53 list-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --output json
)"

# Find DS records which do NOT have an NS record with the same name.
STALE_DS="$(
    jq -c '
        .ResourceRecordSets as $records
        | [
            $records[]
            | select(.Type == "DS") as $ds
            | select(
                ([
                    $records[]
                    | select(.Type == "NS")
                    | .Name
                ] | index($ds.Name)) == null
            )
        ]
    ' <<< "$RECORDS"
)"

COUNT="$(jq 'length' <<< "$STALE_DS")"

if [[ "$COUNT" -eq 0 ]]; then
    echo "No stale DS records found."
    exit 0
fi

echo "Found $COUNT DS record(s) without a matching NS delegation:"

jq -r '.[] | "  \(.Name)"' <<< "$STALE_DS"

if [[ "$DELETE" -eq 0 ]]; then
    echo
    echo "Dry run: nothing was deleted."
    echo "Run with --delete to remove these DS records."
    exit 0
fi

echo
echo "Deleting stale DS records..."

CHANGES="$(
    jq -c '
        {
            Changes: [
                .[] |
                {
                    Action: "DELETE",
                    ResourceRecordSet: .
                }
            ]
        }
    ' <<< "$STALE_DS"
)"

CHANGE_ID="$(
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "$CHANGES" \
        --query 'ChangeInfo.Id' \
        --output text
)"

echo "Route53 change submitted: $CHANGE_ID"
echo "Waiting for Route53 to become INSYNC..."

while true; do
    STATUS="$(
        aws route53 get-change \
            --id "$CHANGE_ID" \
            --query 'ChangeInfo.Status' \
            --output text
    )"

    echo "Route53 status: $STATUS"

    case "$STATUS" in
        INSYNC)
            echo "Route53 change is INSYNC."
            break
            ;;
        PENDING)
            sleep 2
            ;;
        *)
            echo "Unexpected Route53 change status: $STATUS" >&2
            exit 1
            ;;
    esac
done
