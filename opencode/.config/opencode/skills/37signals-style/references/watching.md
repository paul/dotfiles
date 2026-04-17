# Watching

The useful idea here is explicit subscription data, not delegated types or `Current`-driven model APIs.

## Keep

- watching/following is often its own domain concept
- a dedicated join model can be clearer than boolean flags
- activity subscriptions should be queryable and explicit

## Compatible Adjustments

- no `delegated_type`
- no polymorphic joins as the default answer
- no model methods whose default actor comes from hidden globals
- subscription changes should go through explicit transactions when they mutate state
