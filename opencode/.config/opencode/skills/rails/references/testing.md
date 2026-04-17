# Testing

Use RSpec and dependency injection.

## Priorities

- Transactions get the most coverage.
- Adapters and clients are tested at the HTTP boundary.
- Phlex components are tested when they contain meaningful conditional rendering.
- System specs are smoke tests for critical user flows.

## Default Stance

- RSpec, not Minitest.
- Fakes and DI seams, not hidden mocks.
- WebMock or WebValve for external HTTP.
- No VCR.
- No fixtures as the core testing strategy.

## What Not to Test

- Thin models that only declare associations, scopes, validations, and enums.
- Thin controllers whose only job is rendering or calling a transaction.
- Request specs when a system spec is the better end-to-end check.

## Transaction Specs

Every transaction spec should prove the happy path first, then cover important failure paths.

```ruby
describe Movies::Import do
  subject { described_class.call(path:) }

  it { is_expected.to be_success }
end
```

## DI Over Mocks

If a test needs to stub internals, stop and add an injected collaborator instead.
