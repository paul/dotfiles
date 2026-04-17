---
name: tickets
description: Reusable guidance for working with the tk ticket CLI in local-first repositories. Load when the project has a ./.tickets directory or TICKETS_DIR env defined.
---

# Tickets Skill

Use this skill when `tk` is available for the current project, as indicated by either `./.tickets/` in the repo or a `TICKETS_DIR` environment variable.

## Topic Map

### Workflow
- `references/workflow.md` - Session lifecycle, approval gates, and ticket hygiene.

### Commands
- `references/commands.md` - Small, high-value `tk` command reference for common work.

## Scope

This skill covers reusable `tk` workflow and command usage.

If neither `./.tickets/` nor `TICKETS_DIR` exists, do not load this skill and do not mention tickets or `tk`.

## Mode Selection

After loading the skill, choose one of these modes:

- `private` if the ticket directory is gitignored.
- `private` if the repo instructions or docs tell contributors to use another issue tracker for team workflow, such as Linear or Jira.
- Otherwise use `shared`.

## Shared Vs Private

- `shared`: tickets are part of the repo workflow. Ticket IDs may appear in branches, commits, and PRs. Ticket files may be staged and committed when the project tracks them.
- `private`: tickets are for personal tracking only. Do not mention ticket IDs in branches, commits, PRs, or other team trackers. Do not stage or commit ticket files.
