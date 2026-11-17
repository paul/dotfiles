---
name: merge-pr
description: >-
  Merge an approved PR, or a whole gh-stack stack of PRs at once, after a check of every PR's
  checks, review and Deploy section. Records the merge SHA for deploy monitoring. Load it from
  /merge or /ship.
---

# Merge PR

Merge one stack. A PR with no stack is a stack of one. Loading this skill from `/merge` or `/ship`
is the user's approval to merge this stack, once, after the checks below pass. It is not approval
to merge anything else.

## 1. Find the stack

Find the stack as the `babysit` skill's §1 does: `gh stack view --json`, or the current branch's
PR when the branch is in no stack. The argument may name a PR or a stack number instead. Load the
`gh-stack` skill before any other `gh stack` command.

## 2. Check every PR

For each open PR in the stack:

```sh
gh pr view <n> --json number,url,state,isDraft,mergeStateStatus,headRefOid,body,statusCheckRollup,reviews
```

Every PR must have:

- `state` OPEN and `isDraft` false;
- every check in `statusCheckRollup` passing (success, skipped or neutral);
- an approving review from the project's review bot on `headRefOid`, if the project has one (for
  example, the `pr-review` skill's `<!-- pr-review:sha=<sha> -->` marker);
- no unresolved review thread (the GraphQL query in the `babysit` skill's §3);
- `mergeStateStatus` that is not `DIRTY` (conflict) or `BLOCKED`.

`gh stack merge` itself checks only "open and not a draft", so this step is the real gate. If any
PR fails, report each failure and stop. Do not fix anything here. That is `babysit`'s job.

## 3. Read the Deploy sections

Find the Deploy section in each PR body. If any PR has one, stop before the merge:

- Show each section, with its PR number.
- Show each "Before merging" step as a task the user must do first.
- Ask: "Merge?" Merge only after a yes in this session, given after the sections were shown.

## 4. Merge

Use the merge method from the project instructions. If they name none, use merge commits when
`git log --merges -5 origin/main` lists any.

- Stack: `gh stack merge <top PR number> --yes --merge` (or `--squash`, `--rebase`). It merges
  the whole stack in one all-or-nothing step.
- Stack of one: `gh pr merge <n> --merge`.

If the merge fails, report GitHub's reason and stop. Never retry with an admin or bypass option.

## 5. Record the merge

```sh
gh pr view <top PR number> --json mergeCommit --jq .mergeCommit.oid
```

A stack merge gives every PR in the stack the same merge commit. That SHA is the input to deploy
monitoring.

Do not remove the worktree or the local branches. This session may run inside the worktree.

## 6. Report

- The merged PRs, as links, and the merge SHA.
- Each "After deploy" step from the Deploy sections, as a task for the user.
- The cleanup command, if the project uses worktrunk: `wt remove <branch>`.
