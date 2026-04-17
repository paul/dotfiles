# Workflow

Use `tk` as the source of truth for local work tracking.

## Quick Reference

```bash
tk ready       # Find available work
tk show <id>   # Read the ticket before changing code
tk start <id>  # Mark the ticket in progress
tk close <id>  # Close the ticket when the work is accepted
```

## Session Flow

1. Find or confirm the ticket.
2. Read the ticket and any dependencies before changing code.
3. Start the ticket with `tk start <id>` when you begin active work.
4. If discussion changes the plan or scope, record that with `tk add-note` or `tk update`. If
   separate work is discovered while discussing or working, create new tickets if needed.
5. Do the work and run the repository's required quality checks.
6. Ask for review before committing or closing work.
7. After approval, update the ticket state and notes, then close it if complete.
8. If the project is using tickets in `shared` mode, stage any ticket updates and new tickets that belong with the work. In `private` mode, do not stage ticket changes.

## Shared Vs Private

- `shared` mode: tickets are part of the project's normal workflow. Ticket IDs may appear in branch names, commit messages, and PR text. Ticket files may be committed when the repo tracks them.
- `private` mode: tickets are only for personal tracking inside a project that uses another shared tracker or does not commit ticket files. Do not mention ticket IDs in branch names, commit messages, PR text, or external trackers like Linear or Jira. Do not stage or commit ticket files.

## Operating Rules

- Do not treat work as done until the ticket state reflects reality.
- If the ticket belongs to a larger parent or epic, inspect that relationship before starting.
- When the work reveals follow-up tasks, file new tickets instead of hiding unfinished work in notes.
- If the requested change is larger or more complex than the ticket suggests, stop and clarify before pushing ahead.

## Notes And Scope Changes

Use `tk add-note <id>` for timestamped progress updates, review context, or decisions made during implementation.

Use `tk update <id>` when the ticket body itself is wrong or incomplete, such as:

- the description no longer matches the agreed work
- design details need to be captured in the ticket
- acceptance criteria changed during discussion

Prefer notes for temporary context and `update` for durable ticket content.

For `tk add-note` and text fields on `tk update`, default to stdin or file input for anything longer than a short plain sentence. This avoids shell-quoting mistakes with markdown, code fences, backticks, quotes, `$`, or `#{...}`.

## Approval And Commit Boundaries

- Pause for user review before committing.
- Do not close a ticket before the user accepts the work.
- Subagents may inspect tickets and implement code, but they must never update tickets or create commits.
- The main agent is responsible for the final ticket state, commit, and handoff.
