#!/bin/sh

set -eux

if [ -n "${CODESPACES-}" ]; then
  ./setup-codespaces.sh
fi
