# Background Jobs

The useful 37signals ideas here are operational, not architectural.

## Keep

- Solid Queue configuration advice
- stagger recurring jobs to avoid spikes
- enqueue after commit
- retry transient infrastructure failures
- make jobs idempotent

## Compatible Adjustments

- do not drive orchestration from model callbacks
- do not hide enqueue logic in concerns
- transactions should decide when async work is scheduled
- jobs should call a transaction or small collaborator, not a fat model API

## Recommended Job Shape

```ruby
class DeliverBundleJob < ApplicationJob
  def perform(bundle_id)
    Notifications::DeliverBundle.call(bundle_id:)
  end
end
```

Keep jobs shallow and explicit.
