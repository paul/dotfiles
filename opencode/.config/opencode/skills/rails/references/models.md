# Models

Use thin Active Record models.

## Models Are For Data Shape

Models should primarily define:

- associations
- scopes
- string enums
- minimal validations that mirror database constraints

## What Does Not Belong Here

- orchestration across records
- external API calls
- controller-style permission checks
- callback-driven business workflows
- cross-cutting behavior mixed in through concerns

Put that logic in transactions, adapters, query objects, or other plain Ruby collaborators.

## State as Records

When a state change needs attribution, timestamps, or metadata, prefer a dedicated record over a boolean flag.

Good examples:

- publication records
- closure/reopen records
- workflow transition records

This keeps history queryable without bloating the parent record with ambiguous columns.
