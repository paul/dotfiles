#!/usr/bin/env bash
# One press: isolate the focused tab as a build space, then open a review agent
# tab and a CodeDiff tab in the same Git worktree.
set -euo pipefail

herdr=${HERDR_BIN_PATH:-herdr}
ctx=${HERDR_PLUGIN_CONTEXT_JSON:-}

ctx_value() {
  if [[ -n $ctx ]]; then
    jq -r "$1 // empty" <<<"$ctx"
  fi
}

notify() {
  "$herdr" notification show "Handoff" --body "$1" >/dev/null 2>&1 || true
}

fail() {
  notify "$1"
  echo "handoff: $1" >&2
  exit 1
}

workspace=${HERDR_WORKSPACE_ID:-}
tab=${HERDR_TAB_ID:-}
pane=${HERDR_PANE_ID:-}
[[ -n $workspace ]] || workspace=$(ctx_value '.workspace_id')
[[ -n $tab ]] || tab=$(ctx_value '.tab_id')
[[ -n $pane ]] || pane=$(ctx_value '.focused_pane_id')

[[ -n $workspace && -n $tab ]] || fail "missing herdr workspace or tab context"

tabs=$("$herdr" tab list --workspace "$workspace") || fail "could not list tabs"
count=$(jq -r '.result.tabs | length' <<<"$tabs")

if jq -e '[.result.tabs[].label] | any(. == "review" or . == "code")' <<<"$tabs" >/dev/null 2>&1; then
  notify "This space already has review/code tabs."
  exit 0
fi

label=$(ctx_value '.tab_label')
if [[ -z $label ]]; then
  label=$("$herdr" tab get "$tab" 2>/dev/null | jq -r '.result.tab.label // empty' || true)
fi

# Prefer the live foreground cwd of the focused pane. Fall back to the cwd
# herdr captured for the pane/workspace.
cwd=$(ctx_value '.focused_pane_cwd')
[[ -n $cwd ]] || cwd=$(ctx_value '.workspace_cwd')
if [[ -n $pane ]]; then
  live=$("$herdr" pane get "$pane" 2>/dev/null | jq -r '.result.pane.foreground_cwd // empty' || true)
  if [[ -n $live ]]; then cwd=$live; fi
fi

# The build tab may be in a plain directory before its worktree exists. Promote
# it either way, but only open review/code when there is a Git worktree to share.
worktree=""
if [[ -n $cwd ]]; then
  worktree=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
fi

if [[ $count -gt 1 ]]; then
  tab_panes=()
  while IFS= read -r p; do
    [[ -n $p ]] && tab_panes+=("$p")
  done < <("$herdr" pane list --workspace "$workspace" | jq -r --arg tab "$tab" '.result.panes[] | select(.tab_id == $tab) | .pane_id')

  [[ ${#tab_panes[@]} -gt 0 ]] || fail "could not list the tab's panes"

  first=${tab_panes[0]}
  for p in "${tab_panes[@]}"; do
    if [[ $p == "$pane" ]]; then
      first=$p
      break
    fi
  done

  moved=$("$herdr" pane move "$first" --new-workspace --label "${label:-build}" --tab-label build --focus) ||
    fail "could not move the tab into a new space"
  workspace=$(jq -r '.result.move_result.created_workspace.workspace_id // empty' <<<"$moved")
  new_tab=$(jq -r '.result.move_result.created_tab.tab_id // empty' <<<"$moved")
  new_root=$(jq -r '.result.move_result.pane.pane_id // empty' <<<"$moved")
  [[ -n $workspace && -n $new_tab && -n $new_root ]] || fail "could not read the new space from herdr"

  for p in "${tab_panes[@]}"; do
    [[ $p == "$first" ]] && continue
    "$herdr" pane move "$p" --tab "$new_tab" --target-pane "$new_root" --split right --no-focus >/dev/null ||
      fail "could not move a pane into the new space"
  done

  tab=$new_tab
  pane=$new_root
  label=build
fi

if [[ $label != build ]]; then
  notify "Tab is alone in its space but not named build."
  exit 0
fi

if [[ -z $worktree ]]; then
  notify "Promoted to its own space. No Git worktree at ${cwd:-unknown}; review/code not created."
  exit 0
fi

created=$("$herdr" tab create --workspace "$workspace" --cwd "$worktree" --label review \
  --env 'OPENCODE_CONFIG_CONTENT={"default_agent":"review"}' --no-focus) ||
  fail "could not create the review tab"
review_root=$(jq -r '.result.root_pane.pane_id // empty' <<<"$created")
[[ -n $review_root ]] || fail "could not read the review tab from herdr"
# The shared server keeps its own config, so the per-tab default_agent only
# applies to a private server.
"$herdr" pane run "$review_root" opencode || fail "could not start opencode in the review tab"

opened=$("$herdr" plugin pane open --plugin rando.codediff --entrypoint codediff \
  --placement tab --workspace "$workspace" --cwd "$worktree" --no-focus) ||
  fail "could not open the CodeDiff tab"
code_tab=$(jq -r '.result.plugin_pane.pane.tab_id // empty' <<<"$opened")
[[ -n $code_tab ]] || fail "could not read the CodeDiff tab from herdr"
"$herdr" tab rename "$code_tab" code >/dev/null || fail "could not rename the CodeDiff tab"
