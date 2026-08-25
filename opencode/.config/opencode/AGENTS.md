# Agent Instructions

Use ASD-STE100 Simplified Technical English for all writing and communication.

# CRITICAL RULES

- Work is NOT complete until `git commit` succeeds
- **Subagents must NEVER commit.** Only the main (orchestrating) agent may run `git commit`, and
  only after the user has reviewed the changes. Subagents should write files, run linters/tests, and
  report results -- but must leave committing to the main agent.
- If what I'm asking would add significantly more complexity, stop and ask. One of us might be
  misunderstanding the other, don't just brute force a solution. There's almost always a simpler way
  to do something, and if there isn't one, we should figure one out.
- When your own changes introduce regressions, do not keep stacking localized fixes. After one or
  two regressions in the same area, stop and re-evaluate the approach against existing local patterns.
  Prefer replacing the wrong approach over salvaging it.

## Git Lock Handling

- Treat `.git/**/index.lock` errors from `git add`, `git commit`, `git status`, or similar commands
  as transient Git contention first, especially in worktrees with editors, watchers, or other agents
  open.
- Do not immediately investigate the lock file or ask to remove it.
- Retry the failed Git command after a short delay, for example `sleep 0.1`, and retry a few times
  before escalating.
- When chaining staging and committing, prefer either separate Bash calls or include a short pause:
  `git add ... && sleep 0.1 && git commit ...`.
- Only inspect processes or ask about deleting `index.lock` if the lock persists after short retries.
  Never remove a Git lock file without explicit user approval.
