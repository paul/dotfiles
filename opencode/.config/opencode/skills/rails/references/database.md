# Database

This style assumes a single-tenant Rails app backed by SQLite.

## Defaults

- Integer primary keys
- `BetterMigrationDefaults` in migrations
- `discarded_at` soft deletes via the migration defaults
- string enums instead of integer enums

## Schema Design

Add a column when you need to:

- query by it
- index it
- constrain it
- reference it with a foreign key

Put loosely structured metadata in JSON columns when it is not part of query or integrity requirements.

## State as Records

Prefer dedicated state records over booleans when you need attribution, timestamps, or metadata.

## Foreign Keys and Indexes

- Use foreign keys by default.
- Index foreign keys and common filter/sort columns.
- Favor simple, well-supported SQLite patterns over distributed-database design.

## Migrations

Generate migrations with Rails instead of writing files by hand so project defaults apply.
