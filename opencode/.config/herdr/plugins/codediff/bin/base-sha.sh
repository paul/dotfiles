#!/usr/bin/env bash
# Print the commit this worktree was based on.
#
# Worktrees are often stacked on other worktree branches, so the base is not
# necessarily main. The branch reflog records the newest rebase, merge, or
# branch creation.
codediff_base_sha() {
  local cwd=$1
  local base_sha="" current default_ref default upstream reflog entry_sha subject base_ref

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

  printf '%s' "$base_sha"
}
