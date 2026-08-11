# ActionCable

The useful ideas here are about connection safety and broadcast scope, not multi-tenant `Current` wiring.

## Keep

- authenticate WebSocket connections explicitly
- disconnect remote connections when access is revoked
- scope broad broadcasts so they do not fan out unnecessarily

## Compatible Adjustments

- single-tenant app, so no `account_id` or tenant context setup
- avoid `Current` as the transport for connection state
- avoid concern-based broadcast modules for business behavior

## Recommended Shape

- identify the current actor during `connect`
- subscribe views to explicit streams
- when a page needs broad refreshes, scope the stream by the relevant domain object rather than a global bucket
