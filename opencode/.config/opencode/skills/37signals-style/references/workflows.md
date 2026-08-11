# Workflows

The good ideas here are about data modeling, not concern-driven behavior.

## Keep

- state changes often deserve explicit records
- parent changes may need efficient cascading updates
- custom Turbo Stream actions can be useful for focused UI updates

## Compatible Adjustments

- no workflow concerns mixed into models
- no STI command hierarchies
- multi-step workflow changes should be modeled as transactions

## Recommended Shape

- one transaction per workflow mutation
- use `update_all` carefully for deliberate bulk updates
- keep undo logic in a dedicated transaction or collaborator, not an inheritance tree
