# Architecture

Organize business logic as vertical slices under `app/aspects/`. Each slice keeps transactions, forms, components, and external integrations close to the domain they serve.

## Core Structure

- `app/aspects/<domain>/` holds domain-specific transactions, forms, components, adapters, and clients.
- `app/transactions/` is for cross-domain transactions.
- `app/models/` holds thin Active Record models.
- `app/views/` and `app/components/` are Phlex-based.
- `lib/<app>/system/container.rb` defines the root DI container.

## Vertical Slices

Organize code by domain, not by technical role. A slice co-locates the write logic, forms, rendering, and integration code for one concept so changes stay local.

Typical slice structure:

```text
app/aspects/<domain>/
  container.rb
  client.rb
  adapter.rb
  data_models/
  components/
  *.rb
```

- Put transactions for one domain in that domain's slice.
- Put HTML-backed form objects there when they belong to that domain.
- Put domain-aware Phlex components there.
- Put provider integration code there when the domain owns that integration.
- Not every slice needs every layer. A pure write-side slice might have only transactions. An integration-heavy slice might have clients, adapters, and DataModels too.

Use `app/transactions/` only for cross-domain operations that do not belong naturally to a single slice.

## Layers

Every class belongs to exactly one layer. Dependencies point down only.

| Layer | Holds |
|---|---|
| Presentation | controllers, Phlex views and components, forms, filters |
| Application | transactions, policies, notifiers, mailers |
| Domain | models, value objects, DataModels, query objects |
| Infrastructure | clients, adapters, configuration objects, logging, instrumentation |

- A lower layer never reads from a higher one. Models do not read `Current`, params, requests, policies, or components. Transactions do not accept `request` or `params`.
- If a new class needs objects from two layers that are not adjacent, split it.
- A layer may skip the one below it. Do not add pass-through objects only to fill a gap.

## Specification Test

List the cases an object's spec must cover. If a case belongs to another layer's job, move that behavior to that layer.

Example: a controller spec that covers each webhook event type tests application logic. Move the event handling into a transaction and leave one controller case for the wiring.

## New Abstractions

- Do not extract early. Wait until the same shape appears two or three times.
- A new kind of object needs a convention: a base class, a name suffix (`*Query`, `*Filter`, `*Policy`, `*Notifier`), and one public entry method.
- A folder of unrelated objects with no shared interface is not a layer. Split it into named abstractions.

## Refactor Targets

Pick refactor targets by churn × complexity, not by file length.

```sh
git log --format=oneline --since=1.year -- app/models/user.rb | wc -l   # churn
flog -s app/models/user.rb                                              # complexity
```

Start with files in the top ten of both lists.

## Boundaries

- Models define data shape: associations, scopes, string enums, and minimal validations.
- Transactions own write-side business logic and orchestration.
- Forms normalize and validate HTML-backed input.
- Controllers handle HTTP concerns and call transactions for mutations.
- Clients talk to external APIs in provider terms.
- Adapters translate provider data into application terms and return monads.

## External Integrations

Use the client/adapter split:

- Client: HTTP transport, authentication, instrumentation, raw response handling.
- Adapter: application-facing API, response parsing, `Success` / `Failure` return values.

Keep the boundary clean:

- Clients should speak the provider's language and map closely to the provider API surface.
- Clients should raise for transport or HTTP failures instead of returning business-level monads.
- Adapters should accept application inputs, translate to provider inputs, call the client, parse the response, and return monadic results.
- Do not leak provider-shaped hashes far past the adapter boundary.

Use one adapter per provider. Add a swappable backend only when an environment needs different behavior, for example a no-op adapter in staging. Register the backend per environment in the container. Do not branch on the environment inside the adapter.

## Data Models

Use `DataModel` subclasses for external payloads that need validation, coercion, or storage in model columns. Parse at the boundary instead of smearing provider-shaped hashes through the app.
