# Views

Page views live under `app/views/` organized by namespace to mirror routes (e.g. `widgets/`,
`admin/users/`, `sessions/`).

## Conventions

All views inherit from `Views::Base`. Never create intermediate abstract base classes. If multiple
views share behavior, extract it into an Application Component and compose it.

Views should be **thin compositors**. Their job is to arrange page layout using UI Components for
structure and Application Components for domain content. Views should not contain business logic,
data formatting, or domain-aware rendering -- push that into Application Components instead.

```ruby
# Good -- view composes application components and inlines table columns
def view_template
  div(class: "filters") {
    Widgets::Components::StatusFilter(selected_value: @status, turbo_frame: "content")
    Widgets::Components::CategoryFilter(selected_value: @category, turbo_frame: "content")
  }
  UI::DataTable(data: @data, sort_field: @sort_field, sort_order: @sort_order) do |t|
    t.column("Name") { |row| UI::RecordLink(name: row["name"], href: widget_path(row["id"])) }
    t.column("Status") { |row| row["status"] }
  end
end

# Bad -- view calls helpers to build data objects, passes them to UI components
def view_template
  div(class: "filters") {
    UI::FilterDropdown(label: "Status", items: view_context.widget_status_options, ...)
    UI::FilterDropdown(label: "Category", items: view_context.widget_category_options, ...)
  }
  UI::DataTable(columns: view_context.widget_columns, data: @data, ...)
end
```

## Page Metadata

Views declare metadata as class attributes on `Views::Base`. Each accepts a static value or a
lambda resolved at render time:

```ruby
module Views
  module Widgets
    class Show < Views::Base
      title -> { "#{@widget.name}" }
      description -> { "Details for #{@widget.name}" }
      canonical -> { widget_url(@widget) }
    end
  end
end
```

Available metadata attributes:

| Attribute     | Purpose                                    |
|---------------|--------------------------------------------|
| `title`       | `<title>` tag and og:title                 |
| `description` | meta description and og:description        |
| `canonical`   | canonical URL link tag                     |
| `robots`      | robots meta tag (e.g. `"noindex"`)         |
| `og_type`     | Open Graph type (defaults to `"website"`)  |

Override `page_metadata` for dynamic metadata that requires instance data not expressible as a
class-level lambda.

## Layouts

`Views::Base` wraps content in `Views::Layouts::ApplicationLayout` via `around_template`. The
layout is a Phlex component that renders the full HTML document (head, navigation, main). Override
the `layout` class attribute on the view if a page needs a different layout.
