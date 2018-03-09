#!/bin/bash

set -euo pipefail
# set -vx

REPO=9669@usw-s009.rsync.net:backups/borg-repo
MACHINE=$(hostname -s)
export BORG_PASSPHRASE=$(pass show home/rsync.net-borg)

borg create -v --stats                      \
  --compression lz4                         \
  $REPO::${MACHINE}-'{now:%Y-%m-%d}'        \
  /home/rando                               \
  /etc                                      \
  --exclude '/home/*/*.log'                 \
  --exclude '/home/*/*.dump'                \
  --exclude '/home/rando/Dropbox'           \
  --exclude '/home/rando/.cache'            \
  --exclude '/home/rando/Downloads'         \
  --exclude '/home/rando/*/Cache/*'

borg prune -v --list $REPO --prefix ${MACHINE}- \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=12


