# Email

The useful patterns here are around transactional email design and delivery behavior, not tenant context.

## Keep

- mailers should be explicit and boring
- retries belong to transient delivery failures
- previews are useful for keeping templates honest

## Compatible Adjustments

- single-tenant app, so no account-scoped URL generation patterns
- avoid concern-based mailer behavior injection
- prefer transaction-driven enqueue points over model callback-driven delivery
- examples should align with RSpec rather than Minitest fixtures
