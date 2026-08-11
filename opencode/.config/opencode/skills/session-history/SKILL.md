---
name: session-history
description: >
  Use when the user asks a context-recovery question — "what does this code do",
  "why did we decide", "what's the history/context/reasoning behind", "how was X
  implemented", "explain this change", "what was the reasoning", or any question
  that implies historical sessions may contain relevant reasoning, decisions, or
  explanations. Load before answering to search opencode session history for the
  current project.
---

# Session History Skill

When the user asks a question that might be informed by prior work (e.g. "what
does this code do", "why did we decide to do it this way", "how was this
implemented", "explain this", "what's the history/context"), query the opencode
session database **before** answering. This avoids making assumptions or
guess-based explanations.

## Data model

```
Database: ~/.local/share/opencode/opencode.db (SQLite)

project (id, worktree, name)
  └── session (id, project_id, directory, title, time_created, model, agent)
        └── message (id, session_id, data)  -- data is JSON {role, agent, model}
              └── part (id, message_id, session_id, data)  -- data is JSON {type, text}
```

- `session.directory` stores the exact working directory (worktree root)
- `part.data` is JSON: `{"type":"text","text":"..."}` (user text) or
  `{"type":"reasoning","text":"..."}` (assistant chain-of-thought) or
  `{"type":"tool","text":"..."}` (tool calls/results)
- `message.data` is JSON: `{"role":"user","model":...}` or
  `{"role":"assistant","model":...}` — parts belong to a message

## Workflow

### 1. Determine scope

Get the current directory and project root:

```bash
CURRENT_DIR=$(pwd)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$CURRENT_DIR")
DB="$HOME/.local/share/opencode/opencode.db"
```

### 2. Find matching sessions

Match by directory (same worktree); fall back to git root for cross-worktree
matches. Sort by recency.

```bash
sqlite3 "$DB" "
  SELECT id, directory, title, agent, model,
         datetime(time_created/1000, 'unixepoch') as created
  FROM session
  WHERE directory = '$CURRENT_DIR'
     OR directory LIKE '$CURRENT_DIR/%'
     OR directory LIKE '$GIT_ROOT/%'
  ORDER BY time_created DESC
  LIMIT 20;
"
```

### 3. Search session content for keywords

From the user's question, extract 2-4 key terms (function names, file names,
concept words). Search matching sessions' parts for these terms.

```bash
sqlite3 "$DB" "
  SELECT p.session_id, s.title, s.directory, substr(s.title,1,80) as title,
         substr(p.data,1,200) as snippet
  FROM part p
  JOIN session s ON s.id = p.session_id
  WHERE (s.directory = '$CURRENT_DIR'
      OR s.directory LIKE '$CURRENT_DIR/%'
      OR s.directory LIKE '$GIT_ROOT/%')
    AND (
         p.data LIKE '%keyword1%'
      OR p.data LIKE '%keyword2%'
    )
    AND json_extract(p.data, '$.type') IN ('text', 'reasoning')
  ORDER BY s.time_created DESC
  LIMIT 15;
"
```

### 4. Read full context from promising sessions

When a session title or snippet looks relevant, read the full conversation by
fetching all parts ordered chronologically:

```bash
sqlite3 "$DB" "
  SELECT p.data
  FROM part p
  JOIN message m ON m.id = p.message_id
  WHERE p.session_id = '<session_id>'
  ORDER BY m.rowid, p.rowid;
"
```

Decode each JSON blob and reconstruct the conversation. Focus on the parts
with `type` `text` (user's question) and `type` `reasoning` (assistant's
analysis). Skip tool blobs unless the output is needed.

### 5. Summarize and answer

Use the recovered context to answer the user's question. Cite the session
title and date. If nothing relevant is found, state that clearly rather than
speculating.

## Tips

- **Keyword extraction**: From the user's question, pull distinct short phrases
  (e.g. "session history", "auth helpers", "passwordless login", file paths,
  class names, method names).
- **Recency matters**: Recent sessions are more likely to contain relevant
  context, but older ones may have the original decision rationale.
- **Search both text and reasoning**: User messages capture what was asked;
  assistant reasoning captures chains of thought and implementation decisions.
- **Don't dump raw JSON**: Decode/reconstruct the conversation in a readable
  format before presenting it.
- **Rate-limit**: Only query the DB once per relevant question. If the first
  query finds nothing, try broader terms before giving up.
