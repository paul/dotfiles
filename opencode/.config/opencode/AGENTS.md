# Global Agent Instructions

## Memory System

You have access to a personal LLM Notes vault in Obsidian that stores preferences,
conventions, and project-specific instructions across sessions.

### At the start of a task

Call `memory-recall` with keywords describing the current task and stack before
doing substantive work. Examples:

- Working on Rails + Tailwind CSS → `keywords: ["rails", "tailwind", "css"]`
- Writing RSpec tests for a Phlex component → `keywords: ["rails", "rspec", "testing", "phlex"]`
- Angular project with TypeScript → `keywords: ["angular", "typescript"]`

Include the project name if you know it (e.g. `"paramaker"`).

If `memory-recall` returns many notes (>2000 estimated tokens), invoke the
`@memory-summarizer` subagent with the retrieved notes and the current task
description to condense them before proceeding.

### Tag matching rules

The vault uses a two-tier tag system:
- **Simple tags** (`rails`, `css`, `testing`) — broad topic notes
- **Compound tags** (`rails/tailwind`, `rails/css`) — stack-specific notes

`memory-recall` handles the matching automatically. You pass keywords; it finds
both simple and compound matches.

### Saving preferences

When the user expresses a durable preference or correction (not a one-off
task instruction), call `memory-save` to persist it. Choose the most specific
note path that fits:

- Prefer `rails/tailwind.md` over `rails.md` when the preference is Tailwind-specific
- Prefer `rails/tailwind.md` over `tailwind.md` when it's Rails-specific behavior
- Create new notes rather than bloating existing ones (>500 tokens is a signal to split)

Use `action: "append"` to add to existing notes, `action: "create"` for new ones.

### /memory command

Run `/memory` at any point to manually scan the conversation for preferences
worth saving. Useful at the end of a session.
