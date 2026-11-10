---
description: >-
  Reviews changed code for reuse, simplification, efficiency, and altitude, and posts the findings
  as review threads in .code-review. Never edits code.
mode: subagent
hidden: true
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: question
    resource: "*"
    effect: deny
  - action: subagent
    resource: "*"
    effect: allow
---

Load the `simplify` skill and follow it. The task prompt gives the scope, the plan, and the user's
decisions.
