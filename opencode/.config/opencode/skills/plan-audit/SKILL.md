---
name: plan-audit
description: >-
  Audit an implementation plan for a ticket or a stated goal before the user sees it. Checks each
  premise against the source, coverage of the goal, reuse, size, and the project's written rules.
  Read-only. Returns findings classed as mechanical, taste, or user challenge.
---

# Plan audit

Another agent wrote this plan. Do not trust it. Read the source for every claim it makes.

- Do not edit files.
- Do not ask questions. A question for the user is a finding.

## Input

The caller gives you:

- The goal: a ticket ID, or the user's request.
- The current plan.
- The decisions the user made in the session.
- The user challenges already raised. Do not raise them again.

## Step 1: Read

- The ticket, with the ticket tool the project instructions name. Skip this when the goal is a
  request.
- `AGENTS.md`, and each of `REVIEW.md`, `ARCHITECTURE.md`, `STYLE.md` and `TESTING.md` that
  exists.
- Every `README.md` in the directory of each file the plan touches, and in each parent directory up
  to the repo root.

## Step 2: Check

1. **Premises.** List each fact the plan depends on: a class, method, path, option, column, route,
   helper or library behavior. Read the source for each one and quote its `file:line`. For a
   library option, read the library source or its docs, not memory. A premise you cannot confirm
   is a finding.
2. **Already done.** Run `git log --oneline -20 -- <paths>` on the paths the plan touches. Search
   the code for each part the plan builds. A part that already exists is a finding.
3. **Coverage.** Map each acceptance criterion in the ticket, or each thing the request asks for,
   to a plan step or to an explicit deferral. One with neither is a finding.
4. **User decisions.** Each decision from the session must survive in the plan. A step that undoes
   one is a finding.
5. **Reuse and size.** For each new class, helper, component or file, search for an existing one
   that does the job. Name the smallest change that meets the goal. At 8 or more changed files,
   or 2 or more new classes, propose a smaller arrangement with the same behavior, or say why none
   exists.
6. **Written rules.** Check each step against the rules in the project docs from Step 1. Each piece
   must sit in the layer the docs require. Each test must sit at the layer the testing docs
   require.
7. **Docs.** A step that changes a documented pattern must also update that doc.

## Evidence gate

- Each finding quotes the text that motivates it: the source line with its `file:line`, or the plan
  text and the rule it breaks. Drop a finding with no quote.
- Do not report a style preference that no doc states.
- Do not report what the project's CI or linters enforce.

## Classes

- **Mechanical:** one right answer. Give the exact plan change.
- **Taste:** reasonable choices differ. Give the options, recommend one, and say why.
- **User challenge:** the fix changes the goal's scope or a user decision, or the goal is
  ambiguous and the source cannot settle it. Give the question, your default answer, and what
  changes with each answer.

## Output

```markdown
Verdict: clean | findings

### Mechanical
1. <plan step>: <problem>. Evidence: <quote>. Change: <exact plan edit>.

### Taste
1. <plan step>: <options>. Recommend: <option>, because <reason>. Evidence: <quote>.

### User challenges
1. <question>. Default: <answer>. Evidence: <quote>.

### Premises checked
- <premise>: confirmed at <file:line>
```

The verdict is `clean` when there is no mechanical or taste finding. User challenges do not change
the verdict.
