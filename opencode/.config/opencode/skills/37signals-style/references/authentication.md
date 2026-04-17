# Authentication Patterns

The useful part of the original reference is the simple custom-auth idea, not the `Current`-driven controller concern stack.

## Keep

- simple session-based authentication can be better than a heavy auth framework
- magic-link flows are a reasonable pattern for passwordless auth
- rate limit authentication endpoints

## Compatible Adjustments

- avoid `Current` as a global dependency carrier
- avoid concern-heavy controller DSLs for auth behavior
- pass authenticated actors explicitly to transactions and views
- avoid multi-tenant account context patterns

## Recommended Shape

- authentication code may live in `ApplicationController` and dedicated auth helpers
- session lookup is an HTTP concern
- authorization for writes belongs in transactions once the current actor is known
