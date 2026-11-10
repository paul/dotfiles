---
name: watch-reviews
description: >-
  Watch .code-review in the background for new or reopened review threads, and handle them with
  handle-review when they arrive. Use when work is ready for the user to review in the editor.
---

# Watch reviews

Start the watch with the shell tool, with `background: true` and no timeout:

```sh
dir="$(git rev-parse --show-toplevel)/.code-review"
mkdir -p "$dir"
{ ls "$dir" | grep -q '^action-required_' \
  || inotifywait -q -e create -e moved_to -e close_write "$dir"; } \
  && while inotifywait -q -t 20 -e create -e moved_to -e close_write "$dir"; do :; done
ls "$dir" | grep '^action-required_'
```

Do not wait on it in the foreground. Its exit wakes this session. If open threads exist, it does
not wait for a change. It exits 20 seconds after the last change, so a batch of comments wakes the
session once.

When it wakes you:

1. Load the `handle-review` skill and follow it.
2. Start the watch again.

Rules:

- Run one watch at a time.
- Your own writes to `.code-review` wake the watch. Write to it only while no watch runs.
- When the user says the review is done, do not start the watch again. If one still runs, stop
  it: `pkill -f "inotifywait .*$(git rev-parse --show-toplevel)/.code-review"`.
