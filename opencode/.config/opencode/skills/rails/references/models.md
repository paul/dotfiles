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
- presentation helpers such as `full_name` or CSS classes (put them in application components)
- context-specific validations (put them in the form or transaction for that flow)

Put that logic in transactions, adapters, query objects, or other plain Ruby collaborators.

## Allowed Callbacks

Keep a callback in the model only if it changes the record itself and holds in every context:

- `normalizes` for attribute cleanup
- defaults and values derived from the record's own attributes, such as a slug or a word count
- `touch: true` and `counter_cache: true` on `belongs_to`

Move every other callback to a transaction. These are signs that a callback is in the wrong place:

- it calls a mailer, a job, a client, or another aggregate
- it has an `if:` or `unless:` that names a flow, a role, or a consent flag
- the model has a virtual attribute only to skip it (`skip_welcome_email`)

## Value Objects

When predicates and constants cluster around one attribute or a group of columns, extract a value object.

- Use `Data.define` for values built from columns. Expose it from a reader method or `composed_of`.
- Use a `DataModel` for JSON columns that need coercion or validation.

```ruby
MediaType = Data.define(:content_type) do
  FONT_TYPES = %w[font/otf font/woff].freeze

  def font? = FONT_TYPES.include?(content_type)
  def video? = content_type.start_with?("video/")
end

def media_type = media&.content_type&.then { MediaType.new(_1) }
```

## Scopes and Query Objects

- Keep scopes atomic: one condition each. Combine them at the call site.
- Do not put `order` inside a filtering scope. Callers then must use `reorder` to sort the result.
- Move a query to a query object when it joins tables, uses a CTE, combines several scopes, or serves only one feature.

Query objects:

- live in the slice and end in `Query`
- accept a base relation, with a default
- expose `resolve` and return a relation, so callers can chain
- accept domain values, never request params

```ruby
class Users::WithBookmarkedPostsQuery
  def self.resolve(...) = new.resolve(...)

  def initialize(relation = User.all) = @relation = relation

  def resolve(period: Date.current.prev_week.all_week)
    posts = Post.where(created_at: period).where.associated(:bookmarks).select(:user_id).distinct
    @relation.where(id: posts)
  end
end
```

Use Arel instead of SQL strings when a query object is shared across tables. Arel quotes table and column names for you.

## State as Records

When a state change needs attribution, timestamps, or metadata, prefer a dedicated record over a boolean flag.

Good examples:

- publication records
- closure/reopen records
- workflow transition records

This keeps history queryable without bloating the parent record with ambiguous columns.
