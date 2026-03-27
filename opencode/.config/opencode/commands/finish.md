---
description: Run full CI, commit, and optionally open a PR
agent: build
---

The work is done. Now run quality gates, commit, and optionally open a PR.

## Step 1: Read project conventions

Read the following files — skip any that don't exist:

- `CONTRIBUTING.md` — commit message format, PR conventions, branch naming
- `.opencode/instructions.md` — which PR tool to use (`hub`, `gh`, etc.), branching strategy
- `AGENTS.md` — commit rules, ticket lifecycle
- `.github/PULL_REQUEST_TEMPLATE.md` (or equivalent) — PR body sections

## Step 2: Run the full CI suite

Run the **full** CI suite — do not scope it to only changed files. Something you didn't touch may have broken.

Look for a CI script in the project (e.g., `bin/ci`, `make ci`, etc.) and run it. Then run the full test suite separately if the CI script doesn't include it (e.g., `bin/rspec`, `bin/test`, `pytest`, etc.).

**If anything fails: stop immediately.** Report the errors clearly and do not proceed to commit. Fix the failures first, then re-run.

## Step 3: Draft the commit

Draft a commit message following the project's commit conventions (from CONTRIBUTING.md):

- **Subject**: short, imperative, explains *what* the change is. Must begin with one of the allowed prefixes from CONTRIBUTING.md (e.g., Add, Update, Fix, Remove, Refactor).
- **Body**: one or more paragraphs explaining *why* the change was necessary and *how* it was implemented. Write in complete sentences with proper punctuation. Each paragraph covers one idea.
- If a ticket was worked: include the ticket ID and title in the body.

Commit the changes.

## Step 5: Ask about a PR

Ask the user: "Do you want to open a pull request?"

If yes:

1. Read the PR template (`.github/PULL_REQUEST_TEMPLATE.md` or equivalent)
2. Draft the PR body following all required sections in the template
3. Show the draft to the user for review
4. After approval, open the PR using whatever tool the project instructions specify:
   - `hub pull-request -p -m "Title\n\nbody"` (if `hub` is documented)
   - `gh pr create` (if `gh` is documented)
   - Or whatever tool the project instructions specify
5. Return the PR URL

## Step 6: Close the ticket

If the project uses a locally-managed ticket tool (e.g., `tk`): close the ticket with the appropriate command.

If the ticket tool is externally managed (e.g., Jira, Linear): do not change the ticket status.
