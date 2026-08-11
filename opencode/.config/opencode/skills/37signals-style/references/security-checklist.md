# Security Checklist

Keep these patterns; interpret them for a single-tenant self-hosted Rails app.

## Keep

- escape before `html_safe`
- do not HTTP-cache pages with forms
- use CSRF tokens and `Sec-Fetch-Site` as defense in depth where applicable
- protect against SSRF by resolving and validating targets carefully
- configure CSP deliberately
- rate limit authentication and abuse-prone endpoints

## Compatibility Notes

- this app is single-tenant, so tenant-scoping advice does not apply
- avoid concern-based authorization layers as the default
- authorization for mutations should happen in transactions once the actor is known
