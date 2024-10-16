#!/bin/sh

set -eux

env | sort

if [ -n "${CODESPACES-}" ]; then
  ./setup-codespaces.sh
fi
