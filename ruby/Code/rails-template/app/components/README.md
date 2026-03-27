# Components

All components inherit from `Components::Base`. There are two kinds:

**UI Components** (`app/components/ui/`) are generic, reusable building blocks with no domain
knowledge. They get Lookbook previews (`spec/components/previews/`). Corresponding stylesheets
live in `app/assets/stylesheets/`.

**Application Components** (`app/components/<concern>/`, e.g. `app/aspects/<domain>/components/`)
are domain-aware and compose UI components internally to render domain-specific content. They do
**not** get Lookbook previews -- they are exercised through their page views and system specs.
They do not have their own stylesheets; they delegate all visual rendering to UI components.

## Composition Principles

**Single inheritance only.** Every component inherits from `Components::Base`. Every view inherits
from `Views::Base`. Never create intermediate abstract base classes like `Views::AdminBase` or
`Components::FormBase`. If multiple views or components share behavior, extract it into an
Application Component and compose it.

**Composition over inheritance for domain logic.** Application Components contain domain knowledge
and compose UI components for rendering. Views compose Application Components. A view should never
construct UI component data objects directly or call helper methods to build component
configuration -- that's the Application Component's job.

```ruby
# Good -- view delegates to an application component that composes the UI component
Widgets::Components::DetailPanel(widget:)

# Bad -- view reaches through a helper to build UI component data, then calls the UI component
UI::DetailPanel(
  title: view_context.widget_title(widget),
  items: view_context.widget_attributes(widget),
)
```

**Slot methods over Data class construction**. UI components that accept structured child content
must expose a slot DSL method (e.g. `item`, `column`) that callers invoke inside a block.
Callers should never need to know about or construct inner Data classes.

```ruby
# Good -- caller uses slot DSL
UI::Combobox(label: "Status", name: "status") do |cb|
  cb.item(value: "active") { "Active" }
  cb.item(value: "inactive", selected: true) { "Inactive" }
end

# Bad -- caller constructs inner Data class
UI::Combobox(
  label: "Status",
  items: [
    Components::UI::Combobox::Item.new(label: "Active", value: "active"),
    Components::UI::Combobox::Item.new(label: "Inactive", value: "inactive", selected: true),
  ],
)
```

**Component Method Order**. Use a consistent method order in all components:
  1. `initialize`
  2. `view_template` (first method after `initialize`)
  3. Slot DSL methods (e.g. `item`, `row`, `column`)
  4. `private`
  5. `attr_reader` for ivars, like the things captured in slots
  6. `default_attrs` (first private method)
  7. Remaining private helper/render methods

## Creating a New Component

When building a new component, follow these steps:

### 1. Component class (`app/components/<concern>/<name>.rb`)

- Inherit from `Components::Base`.
- Use `Dry::Initializer` for all params and options with proper types:
  ```ruby
  COLORS = Types::Coercible::Symbol.enum(:primary, :secondary, :success, :info, :warning, :danger)
  VARIANTS = Types::Coercible::Symbol.enum(:solid, :soft, :outline, :white)

  param :text, type: Types::Coercible::String, optional: true
  option :color, type: COLORS, default: -> { :secondary }
  option :variant, type: VARIANTS, default: -> { :soft }
  ```
- Implement `default_attrs` returning a hash with `:class` (via `tokens()`) and any other default
  HTML attributes. This gets merged with user-supplied attributes through `attrs`.
- Use `**attrs` on the root element in `view_template` so callers can pass extra HTML attributes.
- Use `sr-only` for screen-reader-only text.

### 2. Yielding and `vanish`

Components that yield an interface (e.g. `item`, `column`) come in two flavors:

**Direct rendering** -- each method call immediately outputs HTML. Good when items render in
document order:

```ruby
def view_template(&)
  nav(class: "nav", &)
end

def item(href, &)
  a(href:, &)
end
```

**Vanishing the yield** -- use `vanish(&)` when you need to collect items *before* rendering (e.g.
to iterate over them multiple times, or to render them in a different order than they were declared).
`vanish` evaluates the block so that the interface methods (like `item`) populate instance data, but
discards any HTML the block might produce. You then render from the collected data afterward:

```ruby
def initialize(...)
  super
  @items = []   # always initialize collections here, not lazily in the slot method
end

def view_template(&)
  vanish(&)     # evaluates block, populates @items, discards output
  ul { items.each_with_index { |item, idx| li(id: "item-#{idx}", **item.except(:content), &item[:content]) } }
end

def item(value:, **attrs, &content)
  items << { value:, **attrs, content: }  # flatten attrs into the hash; store block as content:
end
```

This is the correct pattern whenever a component's block builds up a data structure (array, hash)
that the component loops over during rendering. Without `vanish`, the `@items` array would be empty
when `view_template` tries to render because the block hasn't been called yet.

A few rules for slot methods that collect data:

- **Initialize the collection in `initialize`**, not with `||=` in the slot method. This keeps the
  ivar always available without nil-guarding at every call site.
- **Store the content block as a proc** (`content:` key) rather than calling `capture` eagerly.
  Pass it to the element later with `&item[:content]`. This defers rendering to the right moment.
- **Flatten extra keyword args** into the item hash with `**attrs`. Use `.except(:content, ...)` at
  render time to separate the component's own keys from pass-through HTML attributes.
- **Don't name slot methods after HTML elements** (e.g. `option`, `select`). Phlex registers these
  as element helpers and the name collision causes infinite recursion. Use `item`, `row`, etc.

See [Phlex docs: Vanishing the yield](https://www.phlex.fun/components/yielding.html#vanishing-the-yield)
for the full explanation.

### 3. Stylesheet

For the most part, only UI Components should have styles. Application Components should generally
leverage the utility CSS classes when needed to adjust existing styles.

Create one stylesheet file per component (e.g. `filter_combobox.scss`). Use nested SCSS with `&`
selectors for variants and state — not BEM modifier suffixes:

```scss
// Good -- nested SCSS
.filter-item {
  &.active { background: var(--color-hover); }
}

.filter-search {
  .icon { ... }
  .input { ... }
}

// Bad -- BEM modifiers and flat selectors
.filter-item--active { background: var(--color-hover); }
.filter-search__icon { ... }
.filter-search__input { ... }
```

See `app/assets/stylesheets/README.md` for stylesheet conventions.

### 4. Previews

Only UI Components have previews. Application components generally require too much domain
knowledge to prepare good examples, and since they compose existing UI components would have little
value.
