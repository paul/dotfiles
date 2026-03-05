---
description: Review conversation for preferences to save to LLM Notes vault
subtask: true
model: anthropic/claude-haiku-4-5
---

Review this entire conversation and identify any durable user preferences,
conventions, or instructions that should be saved to the LLM Notes Obsidian vault.

For each preference found:
1. Determine the appropriate note path (e.g. `rails/tailwind.md`, `testing.md`)
2. Determine the appropriate tags (simple tags for broad topics, compound like `rails/tailwind` for stack intersections)
3. Check if that note already exists by calling `memory-recall` with relevant keywords
4. If the note exists and the info is new, call `memory-save` with action `append`
5. If the note doesn't exist, call `memory-save` with action `create`
6. Report back what was saved and where

Only save genuinely durable preferences — not task-specific instructions.
