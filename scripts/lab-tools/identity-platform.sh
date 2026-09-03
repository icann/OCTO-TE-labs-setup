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


apply_identity_platform_hardening () {
    local instance_name="${1:-}"

    if [ -z "$instance_name" ]; then
        echo "ERROR: identity instance name is required." >&2
        return 1
    fi

    if ! lxc info "$instance_name" >/dev/null 2>&1; then
        echo "ERROR: identity instance does not exist: $instance_name" >&2
        return 1
    fi

    echo "Apply - identity-platform hardening: $instance_name"

    if ! lxc exec "$instance_name" -- \
        bash -eu -o pipefail -c '
systemctl mask --now ssh.socket ssh.service

rm -f \
    /etc/sudoers.d/90-cloud-init-users \
    /root/.ssh/authorized_keys \
    /home/ubuntu/.ssh/authorized_keys

if ! getent passwd ubuntu >/dev/null; then
    echo "ERROR: expected ubuntu account is missing." >&2
    exit 1
fi

primary_group=$(id -gn ubuntu)

for group in $(id -nG ubuntu); do
    if [ "$group" != "$primary_group" ]; then
        gpasswd -d ubuntu "$group" >/dev/null
    fi
done

usermod --lock ubuntu
usermod --expiredate 1 ubuntu
usermod --shell /usr/sbin/nologin ubuntu
'; then
        echo "ERROR: failed to harden identity instance: $instance_name" >&2
        return 1
    fi

    echo "Done - Apply identity-platform hardening: $instance_name"
}


validate_identity_platform_hardening () {
    local instance_name="${1:-$IDENTITY_PLATFORM_NAME}"

    echo "Validate - identity-platform hardening: $instance_name"

    if ! lxc info "$instance_name" >/dev/null 2>&1; then
        echo "ERROR: identity instance does not exist: $instance_name" >&2
        return 1
    fi

    if ! lxc exec "$instance_name" -- \
        bash -eu -o pipefail -c '
if ! getent passwd ubuntu >/dev/null; then
    echo "ERROR: expected ubuntu account is missing." >&2
    exit 1
fi

for account in sysadm rtradm; do
    if getent passwd "$account" >/dev/null; then
        echo "ERROR: unexpected account is present: $account" >&2
        exit 1
    fi
done

password_field=$(getent shadow ubuntu | cut -d: -f2)

case "$password_field" in
    "!"*|"*"*)
        ;;
    *)
        echo "ERROR: ubuntu password is not locked." >&2
        exit 1
        ;;
esac

account_expiry=$(getent shadow ubuntu | cut -d: -f8)

if [ "$account_expiry" != "1" ]; then
    echo "ERROR: ubuntu account is not expired." >&2
    echo "Actual shadow expiry field: $account_expiry" >&2
    exit 1
fi

account_shell=$(getent passwd ubuntu | cut -d: -f7)

if [ "$account_shell" != "/usr/sbin/nologin" ]; then
    echo "ERROR: ubuntu account shell is not nologin." >&2
    echo "Actual shell: $account_shell" >&2
    exit 1
fi

primary_group=$(id -gn ubuntu)
group_list=$(id -nG ubuntu)

if [ "$group_list" != "$primary_group" ]; then
    echo "ERROR: ubuntu retains supplementary groups." >&2
    echo "Groups: $group_list" >&2
    exit 1
fi

if [ -e /etc/sudoers.d/90-cloud-init-users ]; then
    echo "ERROR: cloud-init sudoers entry still exists." >&2
    exit 1
fi

if grep -RqsE \
    "^[[:space:]]*ubuntu[[:space:]]" \
    /etc/sudoers \
    /etc/sudoers.d; then
    echo "ERROR: an explicit sudoers entry for ubuntu exists." >&2
    exit 1
fi

for file in \
    /root/.ssh/authorized_keys \
    /home/ubuntu/.ssh/authorized_keys
do
    if [ ! -e "$file" ]; then
        continue
    fi

    if [ ! -f "$file" ]; then
        echo "ERROR: authorized keys path is not a regular file: $file" >&2
        exit 1
    fi

    active_key_count=$(
        awk "NF && \$1 !~ /^#/ {count++} END {print count + 0}" \
            "$file"
    )

    if [ "$active_key_count" -ne 0 ]; then
        echo "ERROR: active authorized keys found in $file: $active_key_count" >&2
        exit 1
    fi
done

for unit in ssh.socket ssh.service; do
    enabled=$(systemctl is-enabled "$unit" 2>/dev/null || true)
    active=$(systemctl is-active "$unit" 2>/dev/null || true)

    if [ "$enabled" != "masked" ]; then
        echo "ERROR: $unit is not masked; enabled=$enabled." >&2
        exit 1
    fi

    if [ "$active" = "active" ]; then
        echo "ERROR: $unit is active." >&2
        exit 1
    fi
done

if ss -lnt \
    | grep -Eq \
        "(^|[[:space:]])[^[:space:]]*:22[[:space:]]"; then
    echo "ERROR: TCP/22 is listening." >&2
    exit 1
fi
'; then
        echo "ERROR: identity-platform hardening validation failed: $instance_name." >&2
        return 1
    fi

    echo "Done - Validate identity-platform hardening: $instance_name"
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

    if ! validate_identity_platform_hardening \
        "$IDENTITY_PLATFORM_NAME"; then
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

    if ! lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        cloud-init status --wait; then
        echo "ERROR: cloud-init failed for $IDENTITY_PLATFORM_NAME." >&2
        return 1
    fi

    # A copied container receives a new cloud-init instance identity.
    # Reapply the security baseline after its first cloud-init run.
    if ! apply_identity_platform_hardening \
        "$IDENTITY_PLATFORM_NAME"; then
        return 1
    fi

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

    if ! lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        cloud-init status --wait; then
        echo "ERROR: cloud-init failed after restarting $IDENTITY_PLATFORM_NAME." >&2
        return 1
    fi

    if ! validate_identity_platform; then
        echo "ERROR: identity-platform creation validation failed." >&2
        return 1
    fi

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

    if ! lxc exec "$IDENTITY_PLATFORM_NAME" -- \
        cloud-init status --wait; then
        echo "ERROR: cloud-init failed while starting $IDENTITY_PLATFORM_NAME." >&2
        return 1
    fi

    if ! validate_identity_platform; then
        echo "ERROR: identity-platform start validation failed." >&2
        return 1
    fi

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
