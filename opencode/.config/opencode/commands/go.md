---
description: Implement the approved plan (switches to build agent)
agent: build
---

The plan has been approved. Now implement it.

If this session has no ticket, skip every ticket step below.

# IF THIS IS THE FIRST TIME YOU ARE IMPLEMENTING THE PLAN:

## Step 1: Update the ticket notes

If the planning session resolved ambiguities, or departed from the ticket in a notable way, add a
note to the ticket with the project's ticket tool. Code review uses these notes to understand why
the implementation differs from the ticket.

## Step 2: Start the ticket

Use the ticket tool named in the project instructions. If the tool manages ticket status,
assign the ticket to the current user and move it to **In Progress**. If the ticket belongs
to an epic that is not in progress, start the epic too. If the ticket is managed outside this
workflow, do not change its status.

## Step 3: Set up the branch

Never work directly on `main`, unless the project instructions or the user say to. Sometimes we do
additional work on the same branch, if the work is related and within scope.

When creating a new branch, derive the branch name from CONTRIBUTING.md's naming convention
(typically `<prefix>/<id>-short-description`).

Some projects use worktrunk to isolate work. The instructions will indicate if this is the case, and
a `.config/wt.toml` file will be present. If so: `wt switch --create <branch>` to create and switch
to a new worktree

## Step 4: Implement the plan

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

Run targeted tests and changed-file linters during implementation, exactly as the project
instructions show them. Do not run the full CI suite, commit, push, or open a pull request.

## Pick the critic model

Pick the newest model made by a different company, at the same strength as your own model. Review
a Claude model with an OpenAI model. Review an OpenAI or DeepSeek model with a Claude model. Find
your own model in your system prompt. Run `opencode models` to find the critic. Do not use a model
with a speed suffix (`-fast`, `-ultrafast`) or a date suffix.

## Review loop

The scope is the files this session changed or added. Other changes in the working tree belong to
someone else. Give every critic:

- The goal (the ticket ID, or the user's request in full) and the file list.
- The approved plan, and the decisions the user made in this session.
- This instruction: review `git diff HEAD -- <files>`, and read each new file in full. Do not ask
  questions; the scope is confirmed.

The critics post their findings as threads in `.code-review`. The threads carry the state between
rounds, so a later critic sees what was fixed and what waits on the user.

Run 3 rounds at most. Start a new session for every subagent; never pass a `sessionID`.

1. **Spawn the critics** in the foreground, with the critic model.
   - Round 1: spawn two subagents in one message, so they run in parallel:
     - `review`: return the verdict, the counts, and the findings it did not write.
     - `simplify`: return the counts and the Dropped list.
   - Rounds 2 and 3: spawn `review` alone, with the same instructions.
2. **Handle the threads.** Load the `handle-review` skill and follow it.
3. **Decide.** The round passes when `review` returns `approved` and you fixed no Simplify Agent
   thread in this round. A Nit fix does not need another round. If the round passes, stop the
   loop. If this was round 3, stop the loop. Otherwise, run the next round.

## Report

Show:

- **Departures:** each place the work diverged from the goal or the approved plan, and why.
  Put this first.
- **Highlights:** the few changes a reviewer should look at first, with links. Do not list every
  changed file.
- **Screenshots:** only if the change touches UI. A fresh screenshot of each changed page or
  component, taken after the last review round. Show each with `read`. If a component cannot
  render, say so.
- **For you:** Anything notable that came up during review, and how it was resolved.
- **Dropped by the critics:** Anything flagged by the critics that you pushed back on, and why.
- If round 3 did not pass: the note that the review did not converge.

Then load the `watch-reviews` skill and start the watch. Stop here. `/finish` owns full CI and the
commit.

DO NOT COMMIT WITHOUT EXPLICIT APPROVAL. If given approval, and a commit is made, then later changes
are requested, DO NOT ASSUME IMPLICIT APPROVAL to automatically commit those changes. Always ask
before amending the previous commit.

Additional Notes:

$ARGUMENTS
