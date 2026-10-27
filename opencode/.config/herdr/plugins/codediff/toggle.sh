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

# Find the point this worktree was based on. Worktrees are often stacked on
# other worktree branches, so the base is not necessarily main. The branch
# reflog records the newest rebase, merge, or branch creation.
base_sha=""
current=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null || true)

default_ref=$(git -C "$cwd" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
default=${default_ref#origin/}
if [[ -z $default ]]; then
  case $current in
    main|master) default=$current ;;
  esac
fi

if [[ -n $current && $current == "$default" ]]; then
  # The default branch has no stack parent. Compare against its upstream so
  # local commits on main show up.
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  if [[ -z $upstream ]] && git -C "$cwd" show-ref --verify --quiet "refs/remotes/origin/$default"; then
    upstream="origin/$default"
  fi
  if [[ -n $upstream ]]; then
    base_sha=$(git -C "$cwd" rev-parse --verify --quiet "${upstream}^{commit}" 2>/dev/null || true)
  fi
elif [[ -n $current ]]; then
  reflog=$(git -C "$cwd" reflog show --format='%H%x09%gs' "refs/heads/$current" 2>/dev/null || true)
  while IFS=$'\t' read -r entry_sha subject; do
    [[ -n $subject ]] || continue
    base_ref=""
    if [[ $subject =~ ^rebase.*\(finish\):.*\ onto\ ([0-9a-f]{7,40})$ ]]; then
      base_ref=${BASH_REMATCH[1]}
    elif [[ $subject =~ ^merge\ (.+):\ Fast-forward$ ]]; then
      base_ref=${BASH_REMATCH[1]}
    elif [[ $subject =~ ^merge\ (.+):\ Merge\ made ]]; then
      base_ref=${BASH_REMATCH[1]}
    elif [[ $subject =~ ^branch:\ Created\ from\ (.+)$ ]]; then
      base_ref=${BASH_REMATCH[1]}
      if [[ $base_ref == HEAD ]]; then base_ref=$entry_sha; fi
    else
      continue
    fi
    if [[ -n $base_ref ]] &&
       base_sha=$(git -C "$cwd" rev-parse --verify --quiet "${base_ref}^{commit}" 2>/dev/null); then
      break
    fi
    base_sha=""
  done <<< "$reflog"
fi

# If the reflog had no usable base, use an upstream only when it names a
# different branch. Do not fall back to main: a stack child must not show
# everything since main.
if [[ -z $base_sha ]]; then
  upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  if [[ -n $upstream && ${upstream#origin/} != "$current" ]]; then
    base_sha=$(git -C "$cwd" rev-parse --verify --quiet "${upstream}^{commit}" 2>/dev/null || true)
  fi
fi

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
