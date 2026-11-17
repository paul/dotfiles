# Review Checklist

Use these smell → fix pairs when you write or review Rails code. Cite the reference file in each review comment.

## Layers (`architecture.md`)

- A model, query object, or policy reads `Current`, params, or the request → pass the value in explicitly.
- A transaction accepts `request` or `params` → pass parsed values or a form.
- A spec covers behavior that belongs to another layer → move that behavior down, and leave one wiring case.
- A new folder of objects has no shared base class, suffix, or entry method → name the abstraction, or keep the code where it was.
- A new abstraction has only one user → inline it until a second user appears.

## Models (`models.md`)

- A callback calls a mailer, a job, a client, or another aggregate → move it to the transaction.
- A callback has a flow-specific `if:`/`unless:`, or the model has a `skip_*` attribute → move it to the transaction.
- A model method formats output for display → move it to an application component.
- Several predicates and constants read the same attribute → extract a value object.
- A filtering scope calls `order` → split the ordering into its own scope.
- A scope joins tables, uses a CTE, or chains several scopes → extract a query object.
- A query object builds SQL strings with interpolated table names → use Arel.

## Reads (`filters.md`)

- An `index` action has a chain of `if params[...]` branches → extract a filter object.
- A filter passes a param value to `where` or `order` without an allowlist → add an allowlist.

## Authorization (`authorization.md`)

- A transaction changes data without a policy check → add the check, and return `Failure(:forbidden)`.
- A controller or view checks roles directly (`user.admin?`) → ask the policy.
- A policy checks roles instead of permissions → map the roles to permissions in one place.
- Request specs cover each permission branch → test the policy as a unit, and cover one denied case per transaction.
- A list checks a policy per row and the rule queries the database → preload, or use a policy scope.

## Notifications (`notifications.md`)

- A transaction or model calls a mailer directly → call a notifier.
- A caller checks notification preferences → move the check into the notifier.
- A new boolean preference column goes on `users` → put it in the preferences model.

## Configuration (`configuration.md`)

- `ENV`, `credentials`, or `config_for` appears in `app/` → read from an injected configuration object.
- `Rails.env.*?` appears in `app/` → add a named setting in `config/`.
- A required secret is read lazily and fails at runtime → load it at boot with `fetch`.
- Tests need real secrets → add test values to the YAML file.

## Observability (`observability.md`)

- `puts`, or a log line in business code that a subscriber can produce → emit an event and log it in a `LogSubscriber`.
- A vendor SDK call reports an error (`Sentry.capture_exception`) → use `Rails.error.report`.
- Metrics are updated inline in business code → update them in a notification subscriber.

## External Integrations (`architecture.md`)

- An adapter has `if Rails.env...` or a config flag to disable it → register a no-op adapter for that environment.
- A swappable backend interface exists with only one implementation → remove the interface.
