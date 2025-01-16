#!/bin/zsh

set -euo pipefail
set -vx

BORG_REPO=de2815@de2815.rsync.net:backups/borg-repo
MACHINE=$(hostname -s)
export BORG_PASSPHRASE=$(pass show home/rsync.net-borg)

borg create -v --stats                      \
  --compression lz4                         \
  --one-file-system                         \
  $BORG_REPO::${MACHINE}-'{now:%Y-%m-%d}'   \
  /home/rando                               \
  --exclude '/home/*/*.log'                 \
  --exclude '/home/*/*.log.*'               \
  --exclude '/home/*/*.dump'                \
  --exclude '/home/*/*.rdb'                 \
  --exclude '/home/rando/Dropbox'           \
  --exclude '/home/rando/NextCloud'         \
  --exclude '/home/rando/.cache'            \
  --exclude '/home/rando/.var'              \
  --exclude '/home/rando/Downloads'         \
  --exclude '/home/rando/*/Cache/*'         \
  --exclude '/home/rando/.local/share/akonadi/*' \
  --exclude '/home/rando/.local/share/containers' \
  --exclude '/home/rando/.local/share/baloo' 

borg prune -v --list --stats $BORG_REPO --prefix ${MACHINE}- --save-space \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=12

