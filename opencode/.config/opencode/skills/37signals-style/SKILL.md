---
name: 37signals-style
description: Select Rails and Hotwire patterns derived from 37signals applications, with the incompatible parts removed. Use only as a supplementary reference alongside the `rails` skill.
---

# 37signals Style Guide

This skill is intentionally narrow. It keeps only patterns derived from 37signals applications after removing the incompatible architecture choices.

## Topic Map

### Frontend & Hotwire
- `references/hotwire.md` — Turbo Drive, Turbo Frames, Turbo Streams patterns
- `references/stimulus.md` — Stimulus controller conventions, value API, targets
- `references/css.md` — CSS organization, naming conventions, component patterns
- `references/action-text.md` — Rich text integration patterns
- `references/actioncable.md` — WebSocket channel patterns

### Application Features
- `references/authentication.md` — Session management, password reset, remember me
- `references/background-jobs.md` — Solid Queue/ActiveJob patterns, retry strategies
- `references/caching.md` — Fragment caching, counter caches, cache keys
- `references/email.md` — Mailer conventions, transactional email patterns
- `references/notifications.md` — In-app notifications, notification objects
- `references/filtering.md` — Search and filter patterns, query objects
- `references/workflows.md` — Multi-step processes, state machines
- `references/webhooks.md` — Inbound/outbound webhook handling

### Infrastructure
- `references/active-storage.md` — File upload conventions, image variants
- `references/configuration.md` — Environment config, credentials, feature flags
- `references/observability.md` — Logging, error tracking, instrumentation
- `references/performance.md` — N+1 prevention, caching strategies, query optimization
- `references/security-checklist.md` — OWASP checklist, Brakeman, safe patterns
- `references/mobile.md` — Mobile-specific patterns, PWA considerations
- `references/ai-llm.md` — LLM/AI integration patterns
- `references/accessibility.md` — Accessibility patterns and ARIA usage
- `references/watching.md` — Activity feeds, event tracking patterns

## Scope

Use the `rails` skill for architecture, models, controllers, views, testing, transactions, forms, and database conventions.
