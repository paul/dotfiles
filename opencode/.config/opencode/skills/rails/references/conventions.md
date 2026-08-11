# Conventions

These are the default Rails conventions for this style.

## Architecture Rules

- Composition over inheritance.
- No `ActiveSupport::Concern` for business behavior.
- No STI, `delegated_type`, or polymorphic joins for domain modeling.
- All writes go through transactions.
- Controllers do not mutate models directly.
- Do not use `Current` as an architectural dependency shortcut.

## Models

Models should usually contain only:

- associations
- scopes
- string enums
- validations that mirror database constraints

If a model grows meaningful business logic, extract it into a transaction or collaborator.

## Error Handling

- Prefer `Success(...)` and `Failure(...)` for business operations.
- Avoid bang methods for normal application flow.
- Raise only for programmer errors or truly exceptional infrastructure failures.

## Dependencies

- Use the dry-rb stack already present in the app.
- Inject infrastructure dependencies explicitly.
- Prefer small plain Ruby objects over magic DSLs.

## Persistence

- Integer primary keys by default.
- SQLite is the primary database assumption.
- Soft deletes come from `discarded_at` via `BetterMigrationDefaults`.

## Views

- Phlex-first.
- Pass explicit data to views and components.
- Keep user-specific rendering inputs explicit instead of hidden globals.
