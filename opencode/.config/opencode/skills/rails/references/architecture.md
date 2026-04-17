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

## Data Models

Use `DataModel` subclasses for external payloads that need validation, coercion, or storage in model columns. Parse at the boundary instead of smearing provider-shaped hashes through the app.
