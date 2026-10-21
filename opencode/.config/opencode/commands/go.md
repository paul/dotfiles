---
description: Implement the approved plan (switches to build agent)
agent: build
---

The plan has been approved. Now implement it.

# IF THIS IS THE FIRST TIME YOU ARE IMPLEMENTING THE PLAN:

## Step 1: Start the ticket

Use the ticket tool named in the project instructions. If the tool manages ticket status,
assign the ticket to the current user and move it to **In Progress**. If the ticket belongs
to an epic that is not in progress, start the epic too. If the ticket is managed outside this
workflow, do not change its status.

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

If the design changed based on review or feedback, record the change on the ticket with the
project's ticket tool.

## Step 2: Implement the work

Same as before:

- If something is surprising or not what you expected, **pause and ask** — do not brute-force through ambiguity
- If a simpler approach becomes apparent during implementation, surface it rather than continuing with the original plan

# Completing the work

Run targeted tests and changed-file linters during implementation. Do not run the full CI
suite, commit, push, or open a pull request. Stop when the implementation is ready for review.
/finish owns full CI and finalization.

Additional Notes:

$ARGUMENTS

