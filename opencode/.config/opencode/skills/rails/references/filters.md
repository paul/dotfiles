# Filters

Use a filter object when an index page narrows or sorts records from user-supplied params.

## Rules

- A filter takes a base relation and params, and returns a relation.
- It accepts only known keys and known values. It ignores or rejects everything else.
- It provides defaults, for example the sort order.
- It reuses atomic scopes and query objects from the domain layer.
- It lives in the slice and ends in `Filter`.

Filters belong to the presentation layer because they read params. Query objects belong to the domain layer and never read params. Forms perform writes and report errors. Filters only read.

## Example

```ruby
class Projects::Filter
  STATUSES = %w[draft published].freeze
  SORTS = %w[name started_at].freeze

  def self.call(relation, params) = new(relation, params).call

  def initialize(relation, params)
    @relation = relation
    @params = params
  end

  def call
    scope = @relation
    scope = scope.where(status: @params[:status]) if STATUSES.include?(@params[:status])
    scope = scope.future if @params[:time] == "future"
    scope = scope.where(Project.arel_table[:name].matches("%#{Project.sanitize_sql_like(@params[:q])}%")) if @params[:q].present?
    scope.order(sort_column => sort_direction)
  end

  private

  def sort_column = SORTS.include?(@params[:sort]) ? @params[:sort] : "started_at"
  def sort_direction = @params[:dir] == "asc" ? :asc : :desc
end
```

The controller makes one call:

```ruby
def index
  render Views::Projects::Index.new(projects: Projects::Filter.call(Project.all, params))
end
```

## Testing

Test the filter as a unit with a real relation. Do not test each filter combination through the controller.
