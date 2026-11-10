---
name: simplify
description: Review changed code for reuse, simplification, efficiency, and altitude, and post the findings as review threads for the builder. Use after implementation, before declaring the work ready for review.
---

# Simplify

Review the changed code for quality, not correctness.

## Scope

The arguments name the scope. Without arguments, the scope is every uncommitted file. Resolve it
once to a list of files, and mark the files the change created.

## Find

Launch four subagents in one message, one per angle. Each one's prompt is `reference/finder-prompt.md`
with its slots filled in, and nothing else. Always launch all four. If a call fails, stop and
report it.

- **Reuse:** flag new code that re-implements something the codebase already has. Grep
  shared/utility modules and files adjacent to the change, and name the existing helper to call
  instead.
- **Simplification:** flag unnecessary complexity the change adds: redundant or derivable state,
  copy-paste with slight variation, deep nesting, dead code left behind. Name the simpler form
  that does the same job.
- **Efficiency:** flag wasted work the change introduces: redundant computation or repeated I/O,
  independent operations run sequentially, blocking work added to startup or hot paths. Also flag
  long-lived objects built from closures or captured environments; they keep the entire enclosing
  scope alive for the object's lifetime, a memory leak when that scope holds large values. Prefer a
  class or struct that copies only the fields it needs. Name the cheaper alternative.
- **Altitude:** check that each change fixes the root cause at the right depth rather than patching
  a symptom with a fragile bandaid. Special cases layered on shared infrastructure are a sign the
  fix is not deep enough. Prefer the simpler, more general change to the underlying mechanism over
  adding special cases, and name that change.

## Post

Read the decisions for this work: the plan and user decisions the caller passed, and the ticket
notes.

Drop a finding only with a quote that refutes it: code that shows the finding is false, or a
recorded decision that picked this exact thing. A decision that assumes the thing works does not
cover a finding that shows it does not.

Every other finding becomes one thread: the finder's quote, the cost, and one fix. Its status is
`action-required`, or `waiting-review` when the change did not touch the code it names.

Read the threads already in `.code-review` for the same file and lines. Skip a finding an open
thread already covers. If a `resolved` thread covers it and the code still has the problem, reply
to that thread with status `action-required`.

Load the `write-review` skill with the author `Simplify Agent`, the severity `minor`, and the
threads and replies.

## Reply

One line per finding, grouped by status (posted, waiting-review, replied, already open, dropped).
