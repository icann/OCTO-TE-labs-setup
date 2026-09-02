#!/bin/bash
#
# Shared identity platform foundation lifecycle
#
# Container:
#   identity-platform
#
# Role:
#   Identity and access platform
#
# Addresses:
#   IPv4: 100.64.0.60
#   IPv6: $IPv6prefix:0::60
#
# Foundation stage:
#   Container lifecycle and network validation only.
#   No authentication services or nginx cutover are enabled yet.
#

IDENTITY_PLATFORM_NAME="identity-platform"
IDENTITY_PLATFORM_TEMPLATE="identityX"
IDENTITY_PLATFORM_IPV4="100.64.0.60"
IDENTITY_PLATFORM_IPV6_HOST="60"


_identity_platform_state () {
    lxc info "$IDENTITY_PLATFORM_NAME" 2>/dev/null \
        | sed -n 's/^Status: //p' \
        || true
}


validate_identity_platform () {
    local state
    local expected_hostname
    local actual_hostname
    local ipv4_output
    local ipv6_output
    local ipv4_routes
    local ipv6_routes

    echo "Validate - identity-platform foundation"

    if ! lxc info "$IDENTITY_PLATFORM_NAME" >/dev/null 2>&1; then
        echo "ERROR: $IDENTITY_PLATFORM_NAME does not exist." >&2
        return 1
    fi

    state="$(_identity_platform_state)"

    if [ "$state" != "RUNNING" ]; then
        echo "ERROR: $IDENTITY_PLATFORM_NAME is not running; state=$state." >&2
        return 1
    fi

    expected_hostname="${IDENTITY_PLATFORM_NAME}.${DOMAIN}"

    if ! actual_hostname="$(
        lxc exec "$IDENTITY_PLATFORM_NAME" -- hostname
    )"; then
        echo "ERROR: unable to read $IDENTITY_PLATFORM_NAME hostname." >&2
        return 1
    fi

    if [ "$actual_hostname" != "$expected_hostname" ]; then
        echo "ERROR: unexpected identity-platform hostname." >&2
        echo "Expected: $expected_hostname" >&2
        echo "Actual:   $actual_hostname" >&2
        return 1
    fi

    ipv4_output="$(
        lxc exec "$IDENTITY_PLATFORM_NAME" -- \
            ip -4 -o address show dev eth0 scope global
    )"

    if ! printf '%s\n' "$ipv4_output" \
        | grep -Fq "${IDENTITY_PLATFORM_IPV4}/22"; then
        echo "ERROR: ${IDENTITY_PLATFORM_IPV4}/22 is not active on eth0." >&2
        return 1
    fi

    ipv6_output="$(
        lxc exec "$IDENTITY_PLATFORM_NAME" -- \
            ip -6 -o address show dev eth0 scope global
    )"

    if ! printf '%s\n' "$ipv6_output" \
        | grep -Fq "::${IDENTITY_PLATFORM_IPV6_HOST}/48"; then
        echo "ERROR: identity-platform IPv6 address is not active on eth0." >&2
        echo "$ipv6_output" >&2
        return 1
    fi

    ipv4_routes="$(
        lxc exec "$IDENTITY_PLATFORM_NAME" -- \
            ip -4 route show default
    )"

    if ! printf '%s\n' "$ipv4_routes" \
        | grep -Fq "via 100.64.0.1"; then
        echo "ERROR: identity-platform IPv4 default route is missing." >&2
        return 1
    fi

    ipv6_routes="$(
        lxc exec "$IDENTITY_PLATFORM_NAME" -- \
            ip -6 route show default
    )"

    if ! printf '%s\n' "$ipv6_routes" \
        | grep -q '^default via '; then
        echo "ERROR: identity-platform IPv6 default route is missing." >&2
        return 1
    fi

    if ! lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        grep -Fq "${IPv6prefix}:0::60/48" \
        /etc/netplan/bb-lxc.yaml; then
        echo "ERROR: identity-platform IPv6 netplan address is incorrect." >&2
        return 1
    fi

    if ! lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        grep -Fq "${IPv6prefix}:0::1" \
        /etc/netplan/bb-lxc.yaml; then
        echo "ERROR: identity-platform IPv6 netplan gateway is incorrect." >&2
        return 1
    fi

    echo "Done - Validate identity-platform foundation"
}


create_identity_platform () {
    local netplan_template
    local rendered_netplan
    local expected_hostname

    echo "Create - identity-platform foundation"

    if lxc info "$IDENTITY_PLATFORM_NAME" >/dev/null 2>&1; then
        echo "ERROR: $IDENTITY_PLATFORM_NAME already exists." >&2
        return 1
    fi

    if ! lxc info "$IDENTITY_PLATFORM_TEMPLATE" >/dev/null 2>&1; then
        echo "ERROR: template $IDENTITY_PLATFORM_TEMPLATE does not exist." >&2
        return 1
    fi

    if [ -z "${workdir:-}" ] || [ ! -d "$workdir" ]; then
        echo "ERROR: deployment workdir is not available." >&2
        return 1
    fi

    if [ -z "${DOMAIN:-}" ] || [ -z "${IPv6prefix:-}" ]; then
        echo "ERROR: DOMAIN and IPv6prefix must be configured." >&2
        return 1
    fi

    netplan_template="../configs/netplan/bb-identity-platform.yaml"
    rendered_netplan="$workdir/bb-identity-platform.yaml"
    expected_hostname="${IDENTITY_PLATFORM_NAME}.${DOMAIN}"

    if [ ! -f "$netplan_template" ]; then
        echo "ERROR: missing netplan template: $netplan_template" >&2
        return 1
    fi

    lxc copy "$IDENTITY_PLATFORM_TEMPLATE" "$IDENTITY_PLATFORM_NAME"
    lxc start "$IDENTITY_PLATFORM_NAME"
    lxc exec "$IDENTITY_PLATFORM_NAME" -- cloud-init status --wait

    lxc config device add "$IDENTITY_PLATFORM_NAME" eth0 nic \
        name=eth0 \
        nictype=bridged \
        parent=net-bb

    sed -e "s|%IPv6pfx%|$IPv6prefix|g" \
        "$netplan_template" \
        > "$rendered_netplan"

    lxc file push \
        "$rendered_netplan" \
        "$IDENTITY_PLATFORM_NAME/etc/netplan/bb-lxc.yaml"

    lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        chmod 600 /etc/netplan/bb-lxc.yaml

    lxc exec "$IDENTITY_PLATFORM_NAME" -- sh -c \
        "printf '%s\n' '$expected_hostname' > /etc/hostname"

    lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        hostname "$expected_hostname"

    lxc exec "$IDENTITY_PLATFORM_NAME" -- sh -c \
        "printf '%s\n' '127.0.0.222 $expected_hostname' >> /etc/hosts"

    lxc exec "$IDENTITY_PLATFORM_NAME" -- netplan apply

    # Confirm that the static network survives a complete restart.
    lxc stop "$IDENTITY_PLATFORM_NAME"
    lxc start "$IDENTITY_PLATFORM_NAME"
    lxc exec "$IDENTITY_PLATFORM_NAME" -- cloud-init status --wait

    validate_identity_platform

    echo "Done - Create identity-platform foundation"
}


delete_identity_platform () {
    echo "Delete - identity-platform"

    if lxc info "$IDENTITY_PLATFORM_NAME" >/dev/null 2>&1; then
        lxc delete --force "$IDENTITY_PLATFORM_NAME"
    else
        echo "$IDENTITY_PLATFORM_NAME is already absent"
    fi

    echo "Done - Delete identity-platform"
}


start_identity_platform () {
    local state

    echo "Start - identity-platform"

    state="$(_identity_platform_state)"

    case "$state" in
        RUNNING)
            echo "$IDENTITY_PLATFORM_NAME is already running"
            ;;
        STOPPED)
            lxc start "$IDENTITY_PLATFORM_NAME"
            ;;
        "")
            echo "ERROR: $IDENTITY_PLATFORM_NAME does not exist." >&2
            return 1
            ;;
        *)
            echo "ERROR: cannot start $IDENTITY_PLATFORM_NAME; state=$state." >&2
            return 1
            ;;
    esac

    lxc exec "$IDENTITY_PLATFORM_NAME" -- cloud-init status --wait
    validate_identity_platform

    echo "Done - Start identity-platform"
}


stop_identity_platform () {
    local state

    echo "Stop - identity-platform"

    state="$(_identity_platform_state)"

    case "$state" in
        RUNNING|FROZEN)
            lxc stop -f "$IDENTITY_PLATFORM_NAME"
            ;;
        STOPPED)
            echo "$IDENTITY_PLATFORM_NAME is already stopped"
            ;;
        "")
            echo "$IDENTITY_PLATFORM_NAME is already absent"
            ;;
        *)
            echo "ERROR: cannot stop $IDENTITY_PLATFORM_NAME; state=$state." >&2
            return 1
            ;;
    esac

    echo "Done - Stop identity-platform"
}
