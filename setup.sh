#!/bin/sh

set -euxo pipefail

if [ -n "${CODESPACES}" ]; then
  ./setup-codespaces.sh
fi
