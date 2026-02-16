#!/usr/bin/env bash
set -euo pipefail

. ./lab-tools/backup.sh

usage() {
  echo "Usage:"
  echo "  restore <group>"
  echo "  restore <group> <name>"
  echo "Examples:"
  echo "  restore 1          # restore all grp1-*"
  echo "  restore 5 ns1      # restore only grp5-ns1"
  exit 1
}

[ "$#" -eq 1 ] || [ "$#" -eq 2 ] || usage

group="$1"
if ! [[ "$group" =~ ^[0-9]+$ ]]; then
  echo "Group must be a number" >&2
  usage
fi

if [ "$#" -eq 2 ]; then
    # Single container
    cname="grp${group}-$2"
    tarball="${backupDIR}/${cname}.tar.gz"
    restore_tarball "$tarball"
else
  # Whole group
  for tarball in "${ backupDIR}"/grp${group}-*.tar.gz; do
    [ -e "$tarball" ] || { echo "No backups for group $group"; exit 2; }
    cname=$(basename "$tarball" .tar.gz)
    restore_tarball "$tarball"
  done
fi

