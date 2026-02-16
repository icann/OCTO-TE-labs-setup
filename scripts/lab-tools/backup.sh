#!/bin/bash

# create backup of all grp servers

backupDIR="backup"

make_backup_all () {

    mkdir -p backup

    for grp in $(seq 1 $NETWORKS); do
        for c in $(lxc list -c n --format csv "grp$grp-"); do
            tarball="${backupDIR}/${c}.tar.gz"
            echo "Creating backup for $c -> $tarball"
            lxc export "$c" "$tarball" --optimized-storage
        done
    done

    echo "Backups created in backup/ directory"
}

restore_tarball() {
    tarball="$1"
    if [ ! -f "$tarball" ]; then
        echo "No backup found: $tarball"
        exit 2
    fi
    # remove existing instance first
    if lxc info "$cname" >/dev/null 2>&1; then
        echo "Instance $cname exists, deleting..."
        lxc delete "$cname" --force
    fi
    echo "Importing $cname from $tarball"
    lxc import "$tarball"
    lxc start $cname
    lxc exec $cname -- cloud-init status --wait
}