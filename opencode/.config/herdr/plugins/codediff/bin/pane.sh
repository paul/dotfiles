#!/usr/bin/env bash
# Start Neovim's CodeDiff in the pane cwd.
#
# HERDR_CODEDIFF_BASE is a full commit SHA chosen by toggle.sh: the point the
# worktree was based on. With it CodeDiff shows the worktree's own commits
# against that base, which matters for worktrees stacked on other worktrees.
# A CodeDiff tab opened directly has no base from toggle.sh, so compute the
# same one here.
set -euo pipefail

base=${HERDR_CODEDIFF_BASE:-}
if ! [[ $base =~ ^[0-9a-f]{7,40}$ ]]; then
  script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
  . "$script_dir/base-sha.sh"
  base=$(codediff_base_sha "$PWD")
fi

if [[ -n $base ]]; then
  exec nvim -c "CodeDiff ${base}... --exit-on-close"
fi

exec nvim -c "CodeDiff --exit-on-close"
