# Hotwire

Most of the Hotwire mechanics remain useful.

## Keep

- Turbo Drive for navigation
- Turbo Frames for lazy loading and focused updates
- Turbo Streams for server-driven UI changes
- Stimulus for the client-side edge where cached or highly interactive behavior needs it

## Compatible Adjustments

- render Turbo payloads with Phlex instead of assuming ERB partials
- avoid examples that depend on `Current` inside cached fragments
- pass explicit IDs or state to Stimulus controllers when client-side personalization is needed
