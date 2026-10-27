#!/usr/bin/env bash
# Start nvim at HERDR_FILE_PATH, optionally at HERDR_FILE_LINE.
set -euo pipefail

file=${HERDR_FILE_PATH:?}
line=${HERDR_FILE_LINE:-}

if [[ $line =~ ^[1-9][0-9]*$ ]]; then
  exec nvim +"$line" "$file"
fi

exec nvim "$file"
