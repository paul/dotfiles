#!/usr/bin/env bash
# Toggle a CodeDiff pane for the focused tab.
#
# The pane is found by its herdr label ("CodeDiff"), which comes from the
# manifest pane title. No state is kept on disk.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
ctx=${HERDR_PLUGIN_CONTEXT_JSON:-}
workspace=${HERDR_WORKSPACE_ID:-}
tab=${HERDR_TAB_ID:-}
pane=${HERDR_PANE_ID:-}

ctx_value() {
  if [[ -n $ctx ]]; then
    jq -r "$1 // empty" <<<"$ctx"
  fi
}

[[ -n $workspace ]] || workspace=$(ctx_value '.workspace_id')
[[ -n $tab ]] || tab=$(ctx_value '.tab_id')
[[ -n $pane ]] || pane=$(ctx_value '.focused_pane_id')

if [[ -z $workspace || -z $tab ]]; then
  echo "codediff: missing herdr workspace or tab context" >&2
  exit 1
fi

existing=$(
  "$herdr" pane list --workspace "$workspace" 2>/dev/null |
    jq -r --arg tab "$tab" '
      [.result.panes[] | select(.tab_id == $tab and .label == "CodeDiff")][0].pane_id // empty'
)

if [[ -n $existing ]]; then
  if "$herdr" plugin pane close "$existing" >/dev/null 2>&1; then
    exit 0
  fi
  # The pane died between the lookup and the close. Fall through and open a
  # fresh one.
fi

# Prefer the live foreground cwd of the focused pane. Fall back to the cwd
# herdr captured for the pane/workspace when the foreground process is gone.
cwd=$(ctx_value '.focused_pane_cwd')
[[ -n $cwd ]] || cwd=$(ctx_value '.workspace_cwd')

if [[ -n $pane ]]; then
  live=$(
    "$herdr" pane get "$pane" 2>/dev/null |
      jq -r '.result.pane.foreground_cwd // empty' || true
  )
  if [[ -n $live ]]; then cwd=$live; fi
fi

if [[ -z $cwd ]]; then
  echo "codediff: no working directory for tab $tab" >&2
  exit 1
fi

if root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
  cwd=$root
else
  "$herdr" notification show "CodeDiff" \
    --body "Not a Git worktree: $cwd" >/dev/null 2>&1 || true
  exit 1
fi

script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$script_dir/bin/base-sha.sh"
base_sha=$(codediff_base_sha "$cwd")

open_args=(
  plugin pane open
  --plugin "${HERDR_PLUGIN_ID:-rando.codediff}"
  --entrypoint codediff
  --placement split
  --direction right
  --cwd "$cwd"
)
if [[ -n $base_sha ]]; then
  open_args+=(--env "HERDR_CODEDIFF_BASE=$base_sha")
fi
open_args+=(--focus)
if [[ -n $pane ]]; then open_args+=(--target-pane "$pane"); fi

opened=$("$herdr" "${open_args[@]}")
new_pane=$(jq -r '.result.plugin_pane.pane.pane_id // empty' <<<"$opened")

if [[ -z $new_pane ]]; then
  echo "codediff: pane open failed: $opened" >&2
  exit 1
fi

# Plugin split panes can start with an unsized pty. This no-op resize makes
# herdr re-push the window size to the new pane and its sibling.
"$herdr" pane resize --pane "$new_pane" --direction left --amount 0 \
  >/dev/null 2>&1 || true
