---
description: Finish, babysit, merge and monitor the current work in one run
agent: build
---

$ARGUMENTS

Ship the current work: commit it, open the PRs, bring them to approval, merge them, and watch the
deploy. Each step must pass before the next one starts. At the first step that stops for the user,
stop the whole run and report.

Running `/ship` grants, for this work only: the commit `/finish` makes, the commits and pushes of
the `babysit` rounds, and one merge of this stack. It grants nothing else.

## Step 1: Finish

Read `~/.config/opencode/commands/finish.md` and follow every step. If CI fails, stop.

## Step 2: Babysit

Load the `babysit` skill and follow it, for the stack Step 1 opened. Continue only if it ends in
Done.

## Step 3: Merge

Load the `merge-pr` skill and follow it, for the same stack. Continue only if the merge succeeds.

## Step 4: Monitor

Load the project's `deploy-monitor` skill and follow it, with the merge SHA from Step 3. If the
project has none, say so and end the run after Step 3.

## Report

- **Result:** Shipped, or the step that stopped and why. Put this first.
- **PRs:** each PR, as a link.
- **Babysit:** the rounds, and anything that was fixed.
- **Deploy:** the run, the monitor's result, and each "After deploy" step as a task for the user.
