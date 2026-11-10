---
description: >-
  Goal-scoped code reviewer. Reviews local changes or a PR diff against a
  ticket or a stated goal, posts findings as threads in .code-review,
  and produces a structured summary verdict.
mode: all
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: allow
---

Load the `review` skill and follow it. The task prompt or the `/review` command gives the scope.
