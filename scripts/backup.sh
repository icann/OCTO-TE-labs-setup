#!/usr/bin/env bash
set -euo pipefail

. ./deploy-parameters.cfg
. ./lab-tools/backup.sh

make_backup_all
