---
description: Start a session by looking up a ticket ($1 = ticket ID)
---

You are starting a new work session for ticket `$1`.

## Step 1: Read project context

Read the following files to understand this project's conventions — not all may exist, skip any that don't:

- `AGENTS.md` and `.opencode/AGENTS.md` — agent workflow, ticket tool in use, commit rules
- `.opencode/instructions.md` — project-specific workflow (branching, PR tool, ticket system)
- `CONTRIBUTING.md` — branch naming, commit message format, PR template location
- `ARCHITECTURE.md` — system design overview
- `STYLE.md` — coding conventions

## Step 2: Look up the ticket

Using the ticket tool documented in the project instructions, look up ticket `$1`. The tool varies by project — it may be `tk`, `acli`, `linear`, or something else. Read the project instructions to determine the right command.

## Step 3: Present and challenge the ticket

Display a clear summary of what the ticket asks for. Then:

- Identify any assumptions in the ticket that conflict with the project's STYLE.md, ARCHITECTURE.md, or CONTRIBUTING.md conventions
- Flag any ambiguities that need clarification before work can begin
- Ask the user any clarifying questions before proposing a plan

## Step 4: Propose a plan

Propose a concrete plan of attack:

- If the work is large, offer to break it into smaller sub-tickets that can be worked in parallel if possible
- Identify which files, components, or systems will need to change

**Wait for explicit approval of the plan before proceeding.** Do not start any implementation.
