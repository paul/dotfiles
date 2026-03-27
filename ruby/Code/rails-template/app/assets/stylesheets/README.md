# Stylesheets

We follow a "vanilla CSS is enough" approach: modern CSS features first, with SCSS used for nesting
and structure where it improves readability.

## File Organization

Stylesheets live flat in `app/assets/stylesheets/`. Keep one file per concept and avoid nested
import trees.

```
app/assets/stylesheets/
├── application.css   # Layer order declaration
├── tokens.css        # Global design tokens and dark-mode overrides
├── reset.css         # CSS reset
├── layout.css        # Base layout helpers
├── typography.css    # Font faces + text utility styles
├── utilities.css     # Utility classes
├── *.scss / *.css    # Component and page styles
└── ...
```

## Build and Entrypoints

- `dartsass-rails` compiles stylesheet sources into `app/assets/builds/`.
- `stylesheet_link_tag :app` in your layout is the app-level include.
- `application.css` is the canonical manifest for layer order.

When you add a new stylesheet file, restart the CSS watcher so dartsass picks it up:
`overmind restart css`

## Specificity and Layers

Declare layer order in `application.css`:

```css
@layer reset, tokens, base, components, modules, utilities;
```

- Use `@layer base` for shared foundations (e.g. `layout.css`, `typography.css`).
- Use `@layer components` for reusable UI pieces.
- Use `@layer modules` for page-level or section-level styles.
- Use `@layer utilities` for additive overrides.

## Tokens and Theming

`tokens.css` is the source of shared CSS custom properties.

- Typography token: `--font-sans`.
- Color tokens: `--color-*` (background, surface, text, border, hover states, brand colors).
- Layout tokens: `--sidebar-width`, `--navbar-height`, etc.
- Radius tokens: `--radius-sm` through `--radius-full`.

Dark mode is variable-based via `html.dark` overrides in `tokens.css`.

## Authoring Guidelines

- Prefer native CSS features; use SCSS when nesting materially improves clarity.
- Use modern CSS features directly where they fit (`:has()`, `@layer`, `color-mix()`,
  `clamp()/min()/max()`, container queries, logical properties).
- Keep component styles in semantic classes and use utilities for one-off adjustments.
- Prefer CSS solutions over JavaScript where possible.
- Ensure styles pass Stylelint:
  `mise exec -- bunx stylelint "app/assets/stylesheets/**/*.{css,scss}"`

## Component Styles

- Keep base styling in semantic component classes (e.g. `.card`, `.button`, `.badge`).
- Use nested SCSS with `&` selectors for variants and state-specific rules.
- Use utilities for one-off adjustments, not as foundational component structure.

```scss
// Good -- nested SCSS
.card {
  &.featured { border: 2px solid var(--color-brand); }
  .card-title { font-weight: bold; }
}

// Bad -- BEM modifiers and flat selectors
.card--featured { border: 2px solid var(--color-brand); }
.card__title { font-weight: bold; }
```

## Motion and Transitions

- Prefer CSS-first animation and transition patterns over JavaScript-driven effects.
- Keep reusable keyframes in dedicated stylesheet files when that improves clarity.
- Use modern CSS transitions for UI state changes (`@starting-style`, `allow-discrete`) where
  browser support is acceptable for the feature.
