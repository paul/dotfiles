# Caching Patterns

The 37signals caching advice is useful when stripped of `Current` and ERB assumptions.

## Keep

- use `fresh_when` and ETags for HTTP caching
- do not HTTP-cache pages with forms
- cache based on the data that affects output
- use touch chains when parent caches should invalidate on child updates
- lazy-load expensive regions with Turbo Frames

## Compatible Adjustments

- make cache inputs explicit instead of relying on globals
- Phlex rendering changes the examples, not the underlying cache principles
- user-specific state should be explicit in the cache key or pushed to client-side behavior when appropriate

## Example

```ruby
def show
  fresh_when etag: [movie, library, timezone]
end
```
