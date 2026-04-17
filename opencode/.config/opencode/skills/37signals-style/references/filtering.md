# Filtering

Filter objects and query objects are still useful patterns.

## Keep the Good Part

Extract filtering from controllers into plain Ruby objects that accept explicit inputs and return relations.

## Compatible Shape

- no controller concerns
- no hidden `Current` access
- no tenant globals
- explicit params in, relation out

```ruby
class Movies::Filter
  def initialize(scope:, params:)
    @scope = scope
    @params = params
  end

  def relation
    result = scope
    result = result.where(state: params[:state]) if params[:state].present?
    result = result.where("title LIKE ?", "%#{params[:query]}%") if params[:query].present?
    result
  end

  private

  attr_reader :scope, :params
end
```

Controllers stay slim by constructing the filter object and rendering the resulting relation.
