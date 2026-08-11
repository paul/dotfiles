# Routing

The useful 37signals routing guidance is still mostly valid.

## Keep

- prefer resourceful routes first
- nest routes when the parent-child relationship matters for the URL
- add custom member or collection actions only when CRUD names stop fitting
- keep route names aligned with domain language

## Compatible Adjustments

- no tenant-prefixed route scopes
- no routing conventions built around `Current` or account context
- route shape should reflect resources, not hidden request globals
