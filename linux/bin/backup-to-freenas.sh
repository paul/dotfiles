#!/bin/bash

set -euo pipefail
# set -vx

REPO=filetank2.home:/mnt/tank/backup/borg
MACHINE=`hostname`
export BORG_PASSPHRASE=$(pass show home/filetank2-borg)

borg create -v --stats                \
  --compression lz4                   \
  $REPO::${MACHINE}-'{now:%Y%m%dT%H%M%S}' \
  /home/rando                         \
  /etc                                \
  --exclude '/home/*/*.log'           \
  --exclude '/home/rando/Dropbox'     \
  --exclude '/home/rando/.cache'      \
  --exclude '/home/rando/Downloads'   \
  --exclude '/home/rando/*/Cache/*'

borg prune -v --list $REPO --prefix ${MACHINE}- \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=12


