---
name: handle-review
description: >-
  Handle the open review threads in .code-review: fix each one or ask the user, reply, and set its
  status. Use after a critic posts threads, or when the user adds comments in the editor.
---

# Handle review

You are the builder. Handle every thread in `.code-review` whose file name starts with
`action-required_`. The threads come from critics (Review Agent, Simplify Agent) and from the
user in the editor. `.code-review` is in the git worktree root.

## Step 1: Read

- List `.code-review/action-required_*.md`. If there is none, say so and stop.
- Read each thread in full. Answer its last comment. The earlier comments are context.
- Read the decisions for this work: the plan, the ticket notes, and the user's messages in this
  session.
- Threads that point at the same mechanism get one fix. Reply to each of them.

## Step 2: Choose an outcome

Give each thread exactly one outcome. Each outcome has a cost. Pay it in full, or pick the other
outcome.

| Outcome | Cost | Status after |
|---|---|---|
| Fix | The edit, and passing targeted tests and linters. | `resolved` |
| Question | A quote of the decision or caller the fix breaks, a code quote that shows why every fix breaks it, and the fix you would apply. | `waiting-review` |

- **Fix** is the default. Apply the thread's fix, or a simpler one that removes the same cost.
  Where the choice is one of taste, apply the thread's recommendation and record the pick.
- **Question.** The thread is right, and every fix breaks a decision or changes intended behavior.
  Before you choose this, look for a fix that keeps the decision. A decision the thread shows is
  false does not block the fix: if the decision says "use A" and A does nothing, make A work. That
  is a Question only when making A work needs a change outside the plan. Name that change.
- Intended behavior is behavior that a caller or a spec exercises. Quote the caller. Code that
  nothing calls has no behavior to change.
- A thread you believe is false, or already decided, is a Question with the proof. The user
  decides. Never resolve it yourself.
- A user's thread that states a change is a Fix. A user's thread that asks or weighs options is a
  Question: answer it, and give the fix you recommend.

## Step 3: Apply and verify

Apply every Fix. Rerun the targeted tests and changed-file linters, as the project instructions
show them, for every file you changed. If a fix fails and one correction does not make it pass,
revert that fix. Its thread becomes a Question that quotes the failure.

## Step 4: Reply

Reply to each thread with `review_reply`, author `Build Agent`, after Step 3:

- **Fix:** what changed, with `file:line`, and the taste pick if any. Status `resolved`.
- **Question:** the quotes, the question, your default answer and the fix you would apply. Status
  `waiting-review`.

Do not start a line in a reply with `### `, and do not write a line that is only `---`. The editor
reads those as thread structure.

## Step 5: Return

- The counts: handled, fixed and questions.
- **Fixed:** one line each, with the thread author and `file:line`.
- **Questions:** one line each, with `file:line` and the question.
