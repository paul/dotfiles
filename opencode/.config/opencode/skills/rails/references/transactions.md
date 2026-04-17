# Transactions

Transactions are the write-side application layer.

## Rules

- Every write operation goes through a transaction.
- Controllers call transactions directly for mutations.
- Business logic belongs here, not in models or controllers.
- Return `Success(...)` and `Failure(...)` instead of encoding failures with exceptions.

## Placement

- Put domain transactions in `app/aspects/<domain>/`.
- Put cross-domain transactions in `app/transactions/`.

## Inputs

- Accept explicit keyword args.
- Accept a `Form` object when the operation is backed by an HTML form.
- Read normalized data from the form instead of reparsing raw params.

## Async Work

Async steps should validate twice:

- before enqueue
- when the job actually runs

Put enqueue conditions in the async target transaction's validator so stale jobs safely no-op.

## Controller Pattern

```ruby
Movies::Update
  .call(movie:, form:, user: current_user)
  .value_or { |failure| failure }
```

Chain directly off the result monad instead of storing unnecessary temporaries.
