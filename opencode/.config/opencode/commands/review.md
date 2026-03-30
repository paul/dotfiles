---
description: Review code changes — ticket, PR, branch, or freeform scope ($ARGUMENTS optional)
agent: review
---

You are starting a code review. The scope is: `$ARGUMENTS`

## Step 1: Read project conventions

Read the following files to understand this project's conventions — skip any that don't exist:

- `.opencode/instructions.md` — branching strategy, PR tool, ticket system, worktree setup
- `CONTRIBUTING.md` — branch naming, commit conventions
- `STYLE.md` — coding conventions to review against
- `ARCHITECTURE.md` — system design patterns

## Step 2: Determine review scope from the arguments

Interpret `$ARGUMENTS` to establish what is being reviewed:

- **Empty** — Check for in-progress tickets using the project's ticket tool (from project instructions). If exactly one is in-progress, use it as scope. If multiple are in-progress or none are found, ask one concise question to clarify what to review.
- **Ticket ID** (e.g., `APP-142`, `sta-83e7`, `#42`) — Look up the ticket using the project's ticket tool. Use the ticket title, description, and acceptance criteria as the review scope. Gather the diff for any uncommitted local changes, or `git diff main...HEAD` if on a feature branch.
- **PR number or GitHub URL** (e.g., `45`, `#45`, `https://github.com/...`) — Fetch PR metadata with `gh pr view {number} --json number,title,body,headRefName,baseRefName,author,url`. Check out the branch with `wt switch {branch}` if `wt` is available, otherwise `git fetch && git checkout {branch}`. Use the PR title and body as the review scope, and `git diff main...HEAD` for the diff.
- **Freeform instructions** (e.g., "this branch against main for code quality") — Treat the text directly as the review goal and scope. Gather whatever diff is appropriate (e.g., `git diff main...HEAD`, `git diff`, etc.).

## Step 3: Gather the diff

Once scope is established, gather the relevant diff. Do not proceed with a review against an empty or unavailable diff — ask the user to clarify what to review.

## Step 4: Conduct the review

Proceed with the review per your operating rules: restrict to the established scope, apply the severity framework, call `review-comment` for each finding, and produce the structured summary verdict.
