# Views

Render views with Phlex.

## Rules

- Prefer Phlex page views and components over ERB partial trees.
- Page views inherit from `Views::Base`.
- Views are thin compositors.
- Shared UI primitives live under `Components::UI`.
- Domain-specific rendering lives in application components, not inline in page views.

## Thin Compositors

Page views arrange layout and hand domain-aware rendering off to application components.

- Keep business logic out of views.
- Keep formatting and domain presentation out of views when it can live in an application component.
- Do not build complex UI data structures through helpers in the view just to feed a generic component.

Good:

```ruby
def view_template
  div(class: "with-sidebar") do
    Widgets::Components::Detail(widget:)
    Widgets::Components::Sidebar(widget:)
  end
end
```

Bad:

```ruby
def view_template
  UI::DetailPanel(items: view_context.widget_rows(widget))
end
```

## Rendering Style

Use Phlex Kit-style calls inside Phlex views and components.

```ruby
Layouts::Head(title: "Application")
UI::Logo()
```

When a component takes a block, pass it directly.

```ruby
Layouts::PageFooter() do |footer|
  footer.link "FAQ", href: "/faq"
end
```

## Page Metadata

Views should declare page metadata on the view class when the app's `Views::Base` supports it.

```ruby
module Views
  module Widgets
    class Show < Views::Base
      title -> { widget.name }
      description -> { "Details for #{widget.name}" }
    end
  end
end
```

Prefer class-level declarations for stable metadata and override an instance method only when the metadata needs richer runtime logic.

## Inputs

- Pass all rendering data explicitly.
- Avoid hidden dependencies on global request context.
- Keep caching inputs visible in the call site.

Views should usually receive the objects they render rather than reaching through globals like `Current` or helper state.

## Turbo

Turbo Frames and Streams are still the transport for partial page updates, but the rendered payloads should come from Phlex components or views.
