# Configuration

Configuration sources belong to the infrastructure layer. Application code reads typed configuration objects, never the sources.

## Kinds of Parameters

| Kind | Examples | Rule |
|---|---|---|
| Settings | thread counts, feature toggles, model names | Give a sensible default. Allow an ENV override. |
| Required secrets | database URL, encryption keys | Fail at boot when missing. |
| Optional secrets | analytics keys, monitoring tokens | When missing, disable the integration with a no-op adapter. |

## Where Values Live

- Sensitive values: Rails credentials. Shared development secrets go in the development credentials.
- Non-sensitive values and test values: `config/<service>.yml`, read with `Rails.application.config_for`.
- Local overrides: ENV.
- Tests need no secrets beyond the files in the repository.

Resolve the source order inside the YAML file with ERB, not in Ruby code:

```yaml
default: &default
  model: "CakeGPT-1.0"
  api_key: <%= ENV.fetch("LAYERIZE_API_KEY") { Rails.application.credentials.dig(:layerize, :api_key) } %>

test:
  <<: *default
  api_key: test-key
```

## Configuration Objects

Give each service one configuration object. Load it once at boot, register it in the container, and inject it.

```ruby
module Layerize
  Config = Data.define(:api_key, :model) do
    def self.load
      yml = Rails.application.config_for(:layerize)
      new(api_key: yml.fetch(:api_key), model: yml.fetch(:model))
    end
  end
end
```

- `fetch` makes a missing required value fail at boot.
- Put derived values and validation on the object.
- Never call `ENV`, `Rails.application.credentials`, or `config_for` from `app/`.

## No Environment Checks in `app/`

Do not call `Rails.env.production?`, `Rails.env.local?`, or similar in application code. Add a named setting instead, and set its default per environment in `config/`.

```ruby
# config/application.rb
config.x.previews_enabled = ENV["PREVIEWS_ENABLED"] == "true" || Rails.env.development?
```

Enforce this rule with a RuboCop cop that flags `Rails.env` outside `config/`.
