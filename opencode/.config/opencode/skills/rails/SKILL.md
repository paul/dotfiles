---
name: rails
description: Authoritative Rails patterns for modern object-oriented Rails applications. Use when writing Rails code that follows transaction-oriented architecture, explicit dependency injection, Phlex views, and RSpec testing.
---

# Rails Skill

This is the authoritative Rails reference in this skill set. When this skill conflicts with generic Rails advice or the `37signals-style` skill, follow this skill.

## Topic Map

### Core Architecture
- `references/architecture.md` — Vertical slices, client/adapter boundaries, DataModel usage, and where code belongs
- `references/conventions.md` — High-level engineering rules for Rails code in this style
- `references/dependency-injection.md` — `Dry::System::Container`, `Dry::AutoInject`, and test seams

### Domain Logic
- `references/transactions.md` — All writes through transactions, monadic flow, async steps, and failure handling
- `references/forms.md` — HTML-backed forms, normalization, coercion, and monadic form objects
- `references/models.md` — Thin Active Record models: associations, scopes, string enums, minimal validations
- `references/controllers.md` — Thin controllers for reads plus transaction-backed writes

### Persistence and Views
- `references/database.md` — Integer PKs, BetterMigrationDefaults, soft deletes, indexes, and SQLite assumptions
- `references/views.md` — Phlex page views, layout patterns, and rendering conventions
- `references/components.md` — Two-tier Phlex components, slot APIs, previews, and composition rules

### Testing
- `references/testing.md` — RSpec, DI-friendly tests, fakes, WebMock/WebValve, and system spec boundaries
