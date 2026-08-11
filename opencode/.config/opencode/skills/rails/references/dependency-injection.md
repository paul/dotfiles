# Dependency Injection

Use explicit dependency injection with `Dry::System::Container` and `Dry::AutoInject`.

## Root Container

`App::Container` owns application-wide infrastructure such as:

- logger
- notifications
- HTTP client
- other stable shared services

Use `App::Deps` to inject them:

```ruby
class SomeClient
  include App::Deps[:http, :logger, :notifications]
end
```

## Aspect Containers

Use aspect-local containers for domain-specific collaborators when a domain has its own internal graph.

```ruby
module TMDB
  class Container
    extend Dry::Container::Mixin

    register(:client) { Client.new }
    register(:adapter) { Adapter.new }
  end

  Import = Dry::AutoInject(Container)
end
```

## Testing

- Prefer injected fakes over mocks.
- Use container stubbing helpers at the boundary.
- Add a DI seam before reaching for `allow` or `expect(...).to receive`.

DI is the replacement for hidden global state. If a class needs something, inject it.
