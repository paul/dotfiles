# Agent Instructions

Use **tk** (ticket) for local issue tracking. Run `tk help` to get started.

## Quick Reference

```bash
tk ready                    # Find available work
tk show <id>                # View issue details
tk status <id> in_progress  # Claim work
tk close <id>               # Complete work
git commit                  # Commit the output, including the ticket.
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git
commit` succeeds and the ticket is closed. DO NOT commit until I have had a chance to review
changes, and explicitly tell you to commit.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update the issue notes** - If we discussed any changes that diverged from the ticket, add a
   summary of our discussion to the notes of the ticket.
4. **Ask for feedback** - Pause and ask the user if the code changes look acceptable, incorporate
   any feedback
5. **Update issue status** - Close finished work, update in-progress items. If there were any
   further notable changes from the review process to the ticket or architecture discussions,
update the ticket notes with a summary.
6. **Commit changes** - Be sure to follow the git commit guidelines in CONTRIBUTING.md.
7. **Clean up** - Remove any temporary or leftover files
8. **Verify** - All changes committed
9. **Hand off** - Provide context for next session

# Git Commits 

- Commit messages include both a subject and a body.
- The Commit subject is short, imperative and explains _what_ the change is for. They should always begin with one of
  only these five prefixes:
  - Add
  - Update
  - Fix
  - Remove
  - Refactor
- Each Git commit almost always includes a body, which explains _why_ the commit was made. It needs to explain the following:
  - Why the change is necessary.
  - How the change was implemented.
- Commit bodies are written as paragraphs.
  - Each paragraph is properly capitalized and reads like a page out of a book. 
  - Each paragraph is devoted to a single idea and uses proper punctuation.

# CRITICAL RULES

- Work is NOT complete until `git commit` succeeds
- **Subagents must NEVER commit.** Only the main (orchestrating) agent may run `git commit`, and
  only after the user has reviewed the changes. Subagents should write files, run linters/tests, and
  report results -- but must leave committing to the main agent.
- If what I'm asking would add significantly more complexity, stop and ask. One of us might be
misunderstanding the other, don't just brute force a solution. There's almost always a simpler way
to do something, and if there isn't one, we should figure one out.
