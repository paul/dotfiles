# Notifications

Several ideas here remain useful once detached from concerns, callbacks, and tenant loops.

## Keep

- prefer `read_at` timestamps over boolean read flags
- bundling by time window is a useful schema pattern
- separate settings records can keep preference data isolated

## Compatible Adjustments

- do not use model callbacks as the primary orchestration mechanism
- do not rely on tenant iteration patterns
- notification creation, bundling, and delivery should be transaction-driven

## Recommended Shape

- creation transaction records the notification
- follow-up transaction decides whether to bundle or deliver
- background jobs trigger explicit delivery transactions
