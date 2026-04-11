---
description: Implement the approved plan (switches to build agent)
agent: build
---

The plan has been approved. Now implement it.

# IF THIS IS THE FIRST TIME YOU ARE IMPLEMENTING THE PLAN:

## Step 1: Mark the ticket in progress

- If the ticket tool manages status locally (e.g., `tk`): mark the ticket in progress using the
  appropriate command. If the ticket belongs to an epic that isn't in progress, start the epic too.
- If the ticket tool is externally managed (e.g., Jira, Linear): do NOT change the ticket status —
  the lifecycle is managed outside this workflow.

## Step 2: Set up the branch

Never work directly on `main`, unless explicitly told to. Sometimes we do additional work on the
same branch, of the work is related and within scope.

When creating a new branch, derive the branch name from CONTRIBUTING.md's naming convention
(typically `<prefix>/<id>-short-description`).

Some projects use worktrunk to isolate work. The instructions will indicate if this is the case, and
a `.config/wt.toml` file will be present. If so: `wt switch --create <branch>` to create and switch
to a new worktree

## Step 3: Implement the plan

Implement the plan that was discussed and approved earlier in this session. Follow the conventions in STYLE.md and ARCHITECTURE.md.

- If something is surprising or not what you expected, **pause and ask** — do not brute-force through ambiguity
- If a simpler approach becomes apparent during implementation, surface it rather than continuing with the original plan

# IF WE HAVE ALREADY STARTED WORK:

## Step 1: Update the ticket if needed

If the design changed based on review or feedback, update the ticket with relevant notes

## Step 2: Implement the work

Same as before:

- If something is surprising or not what you expected, **pause and ask** — do not brute-force through ambiguity
- If a simpler approach becomes apparent during implementation, surface it rather than continuing with the original plan
