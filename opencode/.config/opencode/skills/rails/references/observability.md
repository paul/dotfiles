# Observability

Logging, error reports, and metrics cross every layer. Business code emits events. Subscribers decide what to do with them.

## Instrumentation

Wrap meaningful operations in the injected `notifications` (`ActiveSupport::Notifications`). Name events `<action>.<source>`, for example `fetch_stars.github`.

```ruby
notifications.instrument("fetch_stars.github", repo:) do |payload|
  payload[:stars] = client.stars(repo)
end
```

The event records its duration. When the block raises, the payload gets `:exception` and `:exception_object`.

## Logging

- Use the injected `logger`. Never use `puts`.
- Put per-operation log lines in an `ActiveSupport::LogSubscriber` attached to the event source. Business code then holds no log calls.
- Add request IDs through `config.log_tags`. Use `logger.tagged` for a narrower context.

```ruby
class GitHub::LogSubscriber < ActiveSupport::LogSubscriber
  def fetch_stars(event)
    if (error = event.payload[:exception_object])
      error { "GitHub stars failed for #{event.payload[:repo]}: #{error.message}" }
    else
      debug { "GitHub stars for #{event.payload[:repo]}: #{event.payload[:stars]} (#{event.duration.round(1)}ms)" }
    end
  end
end

GitHub::LogSubscriber.attach_to :github
```

## Errors

Report rescued exceptions with `Rails.error.report(error, handled: true)`. Never call a vendor SDK such as Sentry or Honeybadger from application code.

## Metrics

Update metrics in notification subscribers, not in business code. The metrics backend then stays replaceable.
