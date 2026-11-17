---
description: Watch a production deploy and the hour after it for problems
agent: build
---

Load the project's `deploy-monitor` skill and follow it. The merge SHA is: `$ARGUMENTS`. If it is
empty, use the skill's default.

If the project has no `deploy-monitor` skill, say so and stop.
