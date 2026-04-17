# Commands

Keep this reference small. For anything uncommon, run `tk help` or `tk help <command>`.

These commands apply in both `shared` and `private` modes. The difference is whether ticket IDs and ticket files are allowed to appear in public repo artifacts.

## Pick Work

```bash
tk ready
tk ls --status open
tk search "query"
```

- `tk ready` shows work whose dependencies are already closed.
- `tk ls` is useful when you need a broader filtered list.
- `tk search` helps find tickets by title or body text.

## Inspect And Start

```bash
tk show <id>
tk start <id>
tk dep tree <id>
tk dep cycle
```

- `tk show` prints the full ticket.
- `tk start` marks the ticket `in_progress`.
- `tk dep tree` shows upstream and downstream dependency context.
- `tk dep cycle` is useful when dependency state looks suspicious.

## Update During Work

```bash
tk add-note <id> "Implemented the first pass"
tk update <id> --acceptance @acceptance.md
tk update <id> -d -
```

- `tk add-note` appends a timestamped note.
- `tk update` edits durable ticket fields like description, design, and acceptance criteria.
- Text fields for `tk update` support stdin with `-` and file input with `@path`.

## Create Follow-Up Work

```bash
tk create "Add retry handling" -t task -p 2
tk create "Broken mobile layout" -t bug -p 1
```

- Use `tk create` when new work appears that should not be hidden inside the current ticket.
- Add parent, tags, or acceptance criteria only when they clarify the work.

## Finish Work

```bash
tk close <id>
tk status <id> open
tk status <id> in_progress
```

- `tk close` is the normal way to finish accepted work.
- `tk status` is useful when you need to reopen or correct a state directly.

## Notes about Safe Text Input

Never inline long or complex text in shell quotes for `tk create`, `tk add-note` or `tk update`. If the text is multiline or contains backticks, quotes, `$`, code fences, JSON, or `#{...}`, use stdin or a file.

Preferred pattern: stdin with a single-quoted heredoc.

```bash
tk add-note <id> @- <<'EOF'
Decision: keep the `@graph` structure and remove the old escape hatch.
This note includes `backticks`, "$vars", #{interpolation}, and quotes.
EOF
```

```bash
tk update <id> --acceptance @- <<'EOF'
- Renders one script tag
- Preserves breadcrumb links
- Removes the old untyped metadata escape hatch
EOF
```

```bash
tk add-note <id> @@mention
tk update <id> -d @@literal
```

Only one field may read from stdin in a single invocation. If multiple fields need multiline text, use separate `tk update` calls.

Avoid brittle forms like these:

```bash
tk add-note <id> "text with `backticks`"
tk update <id> -d "$(cat body.md)"
```
