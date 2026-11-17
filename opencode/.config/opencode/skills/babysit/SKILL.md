---
name: babysit
description: >-
  Watch an open PR, or a whole gh-stack stack of PRs, until CI passes and the review bot approves.
  Fix review findings and CI failures for at most 3 rounds, and stop for the user on anything
  security-related or outside the agreed plan. Load it from /babysit or /ship.
---

# Babysit

Bring every open PR in one stack to green checks and an approving review. A PR with no stack is a
stack of one. Be conservative: when in doubt, stop and ask.

## Permission

Loading this skill from `/babysit` or `/ship` grants, for this stack only and for at most 3 rounds:

- Commit fixes to the stack's branches.
- Push them. `gh stack push` (`--force-with-lease`) on the stack's own branches is the only allowed
  force-push.
- Reply on GitHub to comments on the stack's PRs.

It grants nothing else: no amend, no other force-push, no merge, no close, no edit to a PR title
or body, and no rebase outside `gh stack rebase`.

## 1. Find the stack

The target is the argument (a PR number, a PR URL, or a stack number), or the current branch.

- Run `gh stack view --json`. If it exits 0, the stack is its `branches` whose `pr.state` is
  `OPEN`, bottom to top. Load the `gh-stack` skill before any other `gh stack` command.
- If it exits 2, the branch is in no stack. The stack is the current branch's PR alone:
  `gh pr view --json number,headRefName,headRefOid,url`.
- The stack must be checked out in this worktree. If the argument names a PR or stack outside it,
  stop and name the worktree or branch to open.

Read the agreed plan, the ticket notes and the user's messages in this session. They are the
decisions every fix must keep.

## 2. Wait for the checks

Start the wait with the shell tool, with `background: true`. List every open PR in the stack:

```sh
sleep 60
for n in <PR numbers>; do timeout 3600 gh pr checks "$n" --watch --interval 60 > /dev/null 2>&1; done
for n in <PR numbers>; do echo "== #$n"; gh pr checks "$n"; done
```

The first `sleep` gives GitHub time to register the checks of a fresh push. Do not wait in the
foreground. The command's exit wakes this session. A check that is still pending after the
timeout is a stop (§6).

## 3. Read the feedback

For each PR, get the owner and name once with `gh repo view --json owner,name`, then read:

- Failed checks: `gh pr checks <n>`, then `gh run view <run-id> --log-failed`.
- Reviews and PR comments: `gh pr view <n> --json headRefOid,reviews,comments`.
- Review threads, with their resolved state:

  ```sh
  gh api graphql -F o=<owner> -F r=<name> -F n=<n> -f query='
    query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
      reviewThreads(first:100){nodes{isResolved isOutdated comments(first:50){nodes{
        databaseId author{login} body path line createdAt}}}}}}}'
  ```

Every reply this skill posts ends with `<!-- babysit -->`. The user's own comments come from the
same GitHub account, so the marker is the only way to tell the two apart. An item is open when it
is a failed check, or a thread, review or comment whose last entry has no marker and is not
resolved. A comment from the user's account without the marker is the user's own feedback.

## 4. Decide

Load the `handle-review` skill for its Step 2 table only. GitHub takes the place of `.code-review`
here. Give each open item exactly one outcome, Fix or Question:

- Fix every finding the PR caused, Nits included.
- A finding marked Pre-existing (in code the PR does not touch) is a Question: fixing it widens the
  PR's scope.
- A failed check that the PR caused is a Fix. A failure outside the PR (flaky test, outage, a
  failure that `main` also has) is a stop.

**Stop** instead of fixing, and change nothing in this round, when any open item:

- is a Question under the `handle-review` rules, or a finding you believe is false;
- touches security: authentication, authorization, the paywall, payments, secrets, credentials,
  injection, or any finding the reviewer labels as security;
- needs a change to the agreed plan, the PR's Purpose, a migration or schema, or a public
  interface;
- needs a fix that the same check already failed after, in an earlier round.

## 5. Fix round

1. For each PR that has Fix items, check out its branch (`gh stack checkout <branch>`, or stay on
   the branch for a stack of one). Make the fixes on that branch, not on the top branch.
2. Run the targeted tests and changed-file linters, exactly as the project instructions show them.
   If a fix fails and one correction does not make it pass, revert it and stop.
3. Commit once per branch, following the project's commit conventions.
4. For a stack, rebase the layers above: `gh stack rebase --no-trunk`. On a conflict, run
   `gh stack rebase --abort` and stop.
5. If the project requires a full CI run before a push, run it once, on the top branch.
6. Push: `gh stack push` for a stack, `git push` for a stack of one.
7. Reply to each item, and end each reply with `<!-- babysit -->`:
   - an inline thread: `gh api repos/<owner>/<name>/pulls/<n>/comments/<comment-id>/replies -f body="..."`
   - a review body or PR comment: `gh pr comment <n> --body "..."`

   The reply states what changed, with `file:line`. Do not resolve threads.
8. Count the round, then go back to §2.

Each push changes every PR above the fixed layer, so each of them gets a new CI run and a new bot
review. Put all of a round's fixes in one push.

## 6. Finish

**Done** when every open PR in the stack has:

- all checks passing (success, skipped or neutral);
- an approving review from the project's review bot on its current head SHA, if the project has
  one (for example, the `pr-review` skill marks its reviews `<!-- pr-review:sha=<sha> -->`);
- no open item (§3).

**Stop** at a stop condition from §4 or §5, at a check timeout, or when round 3's push still does
not end in Done. Do not start round 4.

Report:

- **Result:** Done, or Stopped with its reason first.
- **Rounds:** the count, and one line per fix with the PR number and `file:line`.
- **For you:** each item that needs the user, with a link to the comment, the question, and the
  fix you would apply.
- **Stack:** one line per PR: number, link, checks, review state.
