# Components

Use a two-tier component system for Phlex.

## Two Tiers

- `Components::UI` holds generic, reusable UI primitives with no domain knowledge.
- Application components live with the domain they serve, usually under `app/aspects/<domain>/components/`.

UI components know how to render reusable interface building blocks. Application components know how to present domain objects by composing those UI primitives.

Views should compose application components. Application components should compose UI components.

## Composition Rules

- Prefer composition over inheritance.
- Use single inheritance only: components inherit from `Components::Base`, views inherit from `Views::Base`.
- Do not create abstract intermediate base classes for domains or component families just to share behavior.
- If multiple components share behavior, extract a collaborator or another component and compose it.

## Slot APIs

For structured child content, expose slot DSL methods such as `item`, `row`, or `column`.

- Prefer slot methods over asking callers to construct internal data objects.
- Keep the caller-facing API in domain language or neutral UI language.
- Avoid slot names that collide with HTML element helpers.

Good:

```ruby
UI::Combobox(label: "Status") do |cb|
  cb.item(value: "active") { "Active" }
end
```

Bad:

```ruby
UI::Combobox(items: [UI::Combobox::Item.new(value: "active", label: "Active")])
```

## Vanishing The Yield

Use `vanish(&)` when a component needs to collect slot calls before rendering them.

```ruby
def initialize(...)
  super
  @items = []
end

def view_template(&)
  vanish(&)

  ul do
    items.each do |item|
      li(&item[:content])
    end
  end
end

def item(**attrs, &content)
  items << { **attrs, content: }
end
```

- Initialize slot collections in `initialize`.
- Store the content block and render it later.
- Flatten pass-through attributes into the collected data and separate them at render time.

## Method Order

Use a consistent method order in components:

1. `initialize`
2. `view_template`
3. slot DSL methods
4. `private`
5. `attr_reader`
6. `default_attrs`
7. remaining helpers

## Previews

Only UI components should usually get Lookbook previews.

- Preview reusable primitives in isolation.
- Exercise application components through page views and higher-level specs instead.
- When a component exposes enums or variants, previews should show the full supported set rather than a random subset.
