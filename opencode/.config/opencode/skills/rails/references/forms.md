# Forms

Forms are for HTML-backed input, not for every operation.

## When to Use a Form

- Use `Form` for update flows that need Rails form builder integration.
- Use a custom form object when input needs normalization or coercion but does not map cleanly to a wrapped model.
- Do not invent a form object for non-HTML workflows just to satisfy a pattern.

## Responsibilities

Forms own:

- param normalization
- coercion
- validation for the HTML flow
- monadic conversion via `to_monad`

Transactions should consume clean form data, not raw controller params.

## Wrapped Forms

```ruby
class Plans::UpdateForm < Form
  wrap Plan, :name, :summary, :description

  validates :name, presence: true
end
```

## Monadic Interface

Forms should return `Success(self)` when valid and `Failure[self, errors:]` when invalid so controllers can chain them into transactions.
