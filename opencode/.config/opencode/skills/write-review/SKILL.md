---
name: write-review
description: >-
  Write review threads and replies to .code-review, exactly as the caller gives them. Shared by
  the review and simplify skills. Decides nothing and never edits code.
---

# Write review

Write what the caller gives you. Do not merge, sort, drop or rewrite anything. The caller has
already decided what to post.

## Input

- The author name, for example `Review Agent` or `Simplify Agent`.
- A list of items. Each item is one of:
  - **New thread:** file, line range, severity, status and comment.
  - **Reply:** thread file name, status and comment.

## Write

- New thread: call `review_comment` with the file, line range, severity, comment, author and
  status.
- Reply: call `review_reply` with the thread, comment, author and status.

A comment must not have a line that starts with `### `, or a line that is only `---`. The editor
reads those as thread structure. If a comment has one, indent that line by two spaces.

If a tool call fails, stop and report the failure with the item that failed. Do not retry
another way.

## Return

One line for each item, with the thread file name the tool returned.
