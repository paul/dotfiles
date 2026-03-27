# Branch Naming

Branches should follow the format `<prefix>/<id>-short-description`, where `<id>` is the ticket
id and `short-description` is a brief, hyphenated summary of the change.

Approved prefixes:

| Prefix     | Use when...                                              |
|------------|----------------------------------------------------------|
| `feat`     | Adding a new feature for the user (MINOR version bump)   |
| `fix`      | Fixing a bug for the user (PATCH version bump)           |
| `docs`     | Documentation-only changes                               |
| `style`    | Code style changes that do not affect logic              |
| `refactor` | Code restructuring that does not add features or fix bugs|
| `test`     | Adding or updating tests                                 |
| `chore`    | Maintenance tasks that do not modify source or test logic|
| `perf`     | Performance improvements                                 |
| `ci`       | Continuous Integration configuration changes             |
| `build`    | Build system or dependency changes                       |
| `revert`   | Reverts a previous commit                                |
| `major`    | A large or breaking change (MAJOR version bump)          |

# Pull Requests

PR bodies must follow the template in `.github/PULL_REQUEST_TEMPLATE.md`:

- **Purpose** (required) — Describe the problem or feature.
- **Approach** (required) — How does this change address the problem?
- **Deploy** (optional) — Extra steps needed as part of the deploy (migrations, rake tasks, feature
  flags, etc.). Omit this section entirely if not applicable.
- **Learning** (optional) — Research notes, links to helpful articles, or anything interesting
  learned during implementation. Omit this section entirely if not applicable.

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
