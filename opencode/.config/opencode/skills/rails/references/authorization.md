# Authorization

Authentication tells who the actor is. Authorization tells whether that actor may do an action on a target.

## Lines of Defense

| Check | Layer | Where |
|---|---|---|
| Authentication | Presentation | controller `before_action` |
| Authorization | Application | policy, called by the transaction |
| System constraints (plan limits, quotas, blocklists) | Application | transaction validator |
| Data consistency | Domain | model validations and database constraints |

Keep each check in its one layer. Code below a check may trust that the check ran.

## Policies

Policies hold the rules. Transactions enforce them. Views use the same policies to hide controls.

- One policy per resource, in the slice, named `<Domain>::Policy` or `<Resource>Policy`.
- The constructor takes the actor and the target. Predicate methods take no arguments.
- Name predicates after the kind of access, such as `view?` and `manage?`. Add an action-specific predicate (`destroy?`) only when its rule differs.
- Check permissions, not roles. Map roles to permission sets in one place.
- Policies never read params, the request, or `Current`.

```ruby
class Books::Policy
  def initialize(user:, book:)
    @user = user
    @book = book
  end

  def view? = true

  def manage?
    @user.permission?(:manage_all_books) ||
      (@user.permission?(:manage_books) && @book.dept == @user.dept)
  end

  alias_method :destroy?, :manage?
end
```

## Enforcement in Transactions

The transaction checks the policy before it changes data. A denial is a `Failure`, not an exception.

```ruby
def call(book:, user:)
  return Failure(:forbidden) unless policy.new(user:, book:).destroy?

  book.discard ? Success(book) : Failure(book.errors)
end
```

Inject the policy class so specs can pass a fake.

For reads, the controller loads the record and asks the policy before it renders. A denied read returns `404` or `403`.

## Views

Hide a control when its action is not allowed. Pass the actor to the component explicitly and ask the same policy.

Do not add a policy predicate for every form field. When one form shows different fields per actor, give the form a method that returns the allowed fields, and back it with the policy.

## Lists

A list that checks a policy per row can cause N+1 queries.

- Preload the associations that the rules read.
- When the list scope already guarantees access, such as "the current user's posts", skip the per-row check.
- Use scope-based authorization (`Books::Policy.scope(user)`) for index pages. It returns only allowed rows, but its queries cost more than a lookup by primary key.

## Testing

- Test every branch of a policy as a unit.
- In each transaction spec, cover one denied case with a fake policy. Do not repeat the policy branches there.
