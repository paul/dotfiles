# Webhooks

The useful parts here are about boundary safety and delivery reliability.

## Keep

- validate and normalize inbound payloads at the boundary
- treat outbound deliveries as retryable infrastructure work
- sign requests and verify signatures when possible
- log attempts and outcomes with enough context to debug failures

## Compatible Adjustments

- no concern-based domain behavior
- no model methods with implicit `Current` actors
- webhook side effects should call transactions or adapters explicitly
- keep inbound parsing and outbound delivery separate from domain orchestration
