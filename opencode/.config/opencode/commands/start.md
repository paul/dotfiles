---
description: Start a session from a ticket ID or a stated goal
agent: plan
---

You are starting a new work session. The arguments are: `$ARGUMENTS`

## Step 1: Read project context

Read these files for design conventions. Skip any that do not exist:

- `ARCHITECTURE.md` — system design overview
- `STYLE.md` — coding conventions

## Step 2: Find the goal

If the arguments start with a ticket ID (for example `gb-47d7`, `APP-142` or `#42`), the goal is
that ticket. The rest of the arguments are notes.

- Use the ticket tool named in the project instructions. If the project has a `.tickets/`
  directory, the tool is `tk`; load the `tickets` skill.
- Get the full ticket: summary, description, acceptance criteria, status, assignee, and
  parent/epic.

Otherwise, the arguments are the goal. There is no ticket. Do not mention tickets in this session.

## Step 3: Present and challenge the goal

Display a clear summary of what the goal asks for. Then:

- Identify any assumptions in the goal that conflict with the project's STYLE.md or ARCHITECTURE.md conventions
- Flag any ambiguities that need clarification before work can begin
- Ask the user any clarifying questions before proposing a plan

## Step 4: Draft a plan

Draft a concrete plan for the code change only: the files, the behavior, and the specs.

- If the work is large, propose sub-tickets that can be worked in parallel. If not, do not mention sub-tickets.
- Leave out ticket notes, ticket status, branches, worktrees, CI, linters, commits, and pull requests. `/go` and `/finish` own them.

Do not show the draft yet.

## Step 5: Audit the plan

Pick the critic model: the newest model made by a different company, at the same strength as your
own model. Review a Claude model with an OpenAI model. Review an OpenAI or DeepSeek model with a
Claude model. Find your own model in your system prompt. Run `opencode models` to find the critic.
Do not use a model with a speed suffix (`-fast`, `-ultrafast`) or a date suffix.

Run the audit for 3 rounds at most:

1. Spawn the `plan-audit` subagent in the foreground, with the critic model. Start a new session
   every round; never pass a `sessionID`. Give it:
   - The goal: the ticket ID, or the user's request in full.
   - The full current plan.
   - The decisions the user made in this session.
   - The user challenges already raised.
2. If the verdict is `clean`, stop the loop.
3. Apply each mechanical finding to the plan. For each taste finding, apply the recommendation and
   record the pick. Add each user challenge to "Questions for you". Do not decide user challenges.
4. If this was round 3, stop the loop. Do not revise the plan again. The round 3 findings are
   unresolved, which signals ambiguity in the goal or the plan.
5. Otherwise, run the next round.

## Step 6: Present the plan

Show the plan, then an "Audit" section:

- The rounds run, and the critic model.
- The changes the audit made to the plan.
- The taste picks, each with the other option.
- "Questions for you": the user challenges.
- If round 3 still had findings: those findings, with the note that the audit did not converge.

Do not ask for approval, and do not describe the next steps. End with the plan, the audit, or open
questions.

Do not start implementation.
