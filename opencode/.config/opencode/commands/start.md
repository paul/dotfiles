---
description: Start a session by looking up a ticket ($1 = ticket ID)
agent: plan
---

You are starting a new work session for ticket `$1`.

## Step 1: Read project context

Read these files for design conventions. Skip any that do not exist:

- `ARCHITECTURE.md` — system design overview
- `STYLE.md` — coding conventions

## Step 2: Look up the ticket

Use the ticket tool named in the project instructions to look up ticket `$1`. The tool varies
by project. Read the project instructions to find the correct command. Get the full ticket:
summary, description, acceptance criteria, status, assignee, and parent/epic.

## Step 3: Present and challenge the ticket

Display a clear summary of what the ticket asks for. Then:

- Identify any assumptions in the ticket that conflict with the project's STYLE.md or ARCHITECTURE.md conventions
- Flag any ambiguities that need clarification before work can begin
- Ask the user any clarifying questions before proposing a plan

## Step 4: Propose a plan

Propose a concrete plan for the code change only: the files, the behavior, and the specs.

- If the work is large, propose sub-tickets that can be worked in parallel. If not, do not mention sub-tickets.
- Leave out ticket status, branches, worktrees, CI, linters, commits, and pull requests. `/go` and `/finish` own them.
- Do not ask for approval, and do not describe the next steps. End with the plan, or with open questions.

Do not start implementation.

Additional Notes:

$ARGUMENTS
