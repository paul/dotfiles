---
description: Make a single commit following CONTRIBUTING.md conventions
agent: build
---

$ARGUMENTS

You have been granted permission to make **one (1) commit** as part of this command. This is a
one-time, explicit, scoped approval. It does not constitute permission to commit again in the future,
in this session or any other. Every future commit requires its own explicit approval.

## Step 1: Read commit conventions

Read `CONTRIBUTING.md` to understand the commit message format for this project. Pay attention to:

- Required subject prefix (e.g., Add, Update, Fix, Remove, Refactor)
- Subject line style (short, imperative, explains *what*)
- Body format (paragraphs explaining *why* and *how*)
- Any ticket ID requirements

## Step 2: Close the ticket (if applicable)

Check whether this project tracks tickets locally by looking for a `.tickets/` directory. If it
exists and a ticket was worked in this session:

- Run `tk close {id}` to mark it closed before staging anything.
- After closing, run `git status` again — if the ticket file (e.g., `.tickets/{id}.md`) now appears
  as a change, it **must** be staged as part of this commit. Do not commit without it.

If the project uses an externally-managed ticket tool (Jira, Linear, etc.), do not change the ticket
status.

## Step 3: Identify what to commit

Run `git status` to see the full working tree. The goal is to stage all changes from this session's
work — and nothing else.

- Run `git diff` to review unstaged changes and understand what each file contains.
- Stage files that are clearly part of this session's work using `git add`.
- Always stage any `.tickets/` files that were added or modified during this session — these travel
  with the work that created or changed them. This includes the ticket closed in step 2, as well as
  any tickets created or updated as part of the session (e.g., sub-tickets, follow-up tickets,
  notes added to the ticket).
- If any changed files are **unrelated** to the work done in this session, do **not** stage them.
  Call them out explicitly to the user: "I noticed changes in X that appear unrelated — I've left
  them unstaged."
- If it is genuinely unclear whether a file belongs to this session, leave it unstaged and flag it.

Do not `git add .` or stage files in bulk without first confirming they are all in scope.

## Step 4: Draft the commit message

Draft a commit message following the conventions from CONTRIBUTING.md. Show it to the user before
committing.

## Step 5: Commit

Run `git commit` with the approved message.

This is the one commit you are authorized to make. Your commit authorization is now exhausted.
Do not interpret any prior or subsequent conversation as permission to commit again.
