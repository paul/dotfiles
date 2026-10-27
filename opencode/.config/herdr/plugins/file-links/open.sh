#!/usr/bin/env bash
# Open a herdr Ctrl+clicked file:// link in a split nvim pane.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
ctx=${HERDR_PLUGIN_CONTEXT_JSON:-}
url=${HERDR_PLUGIN_CLICKED_URL:-}

ctx_value() {
  if [[ -n $ctx ]]; then
    jq -r "$1 // empty" <<<"$ctx"
  fi
}

[[ -n $url ]] || url=$(ctx_value '.clicked_url')
[[ $url == file://* ]] || exit 0

# Strip the scheme and an optional host (file://localhost/path).
rest=${url#file://}
if [[ $rest != /* ]]; then
  rest=/${rest#*/}
fi

# Fragment: file:///path#42 or file:///path#L42. Ignore a query string.
fragment=""
if [[ $rest == *"#"* ]]; then
  fragment=${rest#*#}
  rest=${rest%%#*}
fi
rest=${rest%%\?*}

path=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' "$rest")

line=""
if [[ $fragment =~ ^[Ll]?([0-9]+) ]]; then
  line=${BASH_REMATCH[1]}
  [[ $line == 0 ]] && line=""
fi

# Link clicks carry the clicked pane in the context. Fall back to the calling
# pane for a manual invocation.
clicked_pane=$(ctx_value '.focused_pane_id')
[[ -n $clicked_pane ]] || clicked_pane=${HERDR_PANE_ID:-}

cwd=""
if [[ -n $clicked_pane ]]; then
  cwd=$(
    "$herdr" pane get "$clicked_pane" 2>/dev/null |
      jq -r '.result.pane.foreground_cwd // .result.pane.cwd // empty' || true
  )
fi

if [[ $path != /* ]]; then
  [[ -n $cwd ]] || exit 1
  path="$cwd/$path"
fi

if [[ ! -f $path ]]; then
  "$herdr" notification show "File link" \
    --body "Not found: $path" >/dev/null 2>&1 || true
  exit 1
fi

# Start nvim at the worktree root so file navigation and LSP behave as usual.
root=$(dirname "$path")
if git_root=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null); then
  root=$git_root
fi

open_args=(
  plugin pane open
  --plugin "${HERDR_PLUGIN_ID:-rando.file-links}"
  --entrypoint file
  --placement split
  --direction right
  --cwd "$root"
  --env "HERDR_FILE_PATH=$path"
)
if [[ -n $line ]]; then
  open_args+=(--env "HERDR_FILE_LINE=$line")
fi
open_args+=(--focus)
if [[ -n $clicked_pane ]]; then
  open_args+=(--target-pane "$clicked_pane")
fi

opened=$("$herdr" "${open_args[@]}")
new_pane=$(jq -r '.result.plugin_pane.pane.pane_id // empty' <<<"$opened")
if [[ -z $new_pane ]]; then
  echo "file-links: pane open failed: $opened" >&2
  exit 1
fi

label=$(basename "$path")
[[ -n $line ]] && label="$label:$line"
"$herdr" pane rename "$new_pane" "$label" >/dev/null 2>&1 || true
