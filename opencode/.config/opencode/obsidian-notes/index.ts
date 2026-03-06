import type { Plugin } from "@opencode-ai/plugin"
import memoryRecall from "./tools/memory-recall"
import memorySave from "./tools/memory-save"

const MEMORY_SYSTEM_INSTRUCTIONS = `## Memory System

You have access to a personal LLM Notes vault in Obsidian that stores preferences,
conventions, and project-specific instructions across sessions.

### When to call \`memory-recall\`

Call \`memory-recall\` with relevant keywords in these situations:

1. **Before starting any new task** — always, without exception
2. **When the topic shifts** — e.g. you were fixing a bug and now you're writing tests;
   recall again with testing-related keywords
3. **When you encounter a technology you haven't recalled for yet this session** —
   e.g. if Tailwind comes up and you haven't recalled with \`tailwind\` yet, recall now

The \`keywords\` array is **required** and must reflect the actual stack and topic.
Never call \`memory-recall\` with an empty array or with only a task description.

Examples:
- Styling task in a Rails+Tailwind app → \`["rails", "tailwind", "css"]\`
- Writing RSpec tests for a Phlex component → \`["rails", "rspec", "phlex", "testing"]\`
- Angular app with TypeScript → \`["angular", "typescript"]\`
- Git workflow question → \`["git"]\`

### Tag matching rules

The vault uses a two-tier tag system:
- **Simple tags** (\`rails\`, \`css\`, \`testing\`) — broad topic notes
- **Compound tags** (\`rails/tailwind\`, \`rails/css\`) — stack-specific notes

\`memory-recall\` handles matching automatically. Pass keywords; it returns notes
whose tags match any single keyword, plus notes whose compound tags match when
all parts of the compound are present in your keywords.

### When to call \`memory-save\`

Call \`memory-save\` when the user expresses a durable preference or correction —
something that should apply to future sessions, not just this task.

Examples that warrant saving:
- "Don't use BEM, use nested SCSS"
- "Always write the body in git commits"
- "Use \`tailwindcss-rails\` gem, not the npm package"

Examples that do NOT warrant saving (one-off task instructions):
- "Make this button red"
- "Add a comment here"

Choose the most specific note path:
- Prefer \`rails/tailwind.md\` over \`rails.md\` for Tailwind-in-Rails preferences
- Create new notes rather than bloating existing ones (>500 tokens → split)
- Use \`action: "append"\` for existing notes, \`action: "create"\` for new ones

### \`/memory\` command

Run \`/memory\` at any point to manually scan the conversation for preferences
worth saving. Useful at the end of a session.`

const MEMORY_COMMAND_TEMPLATE = `Review this entire conversation and identify any durable user preferences,
conventions, or instructions that should be saved to the LLM Notes Obsidian vault.

For each preference found:
1. Determine the appropriate note path (e.g. \`rails/tailwind.md\`, \`testing.md\`)
2. Determine the appropriate tags (simple tags for broad topics, compound like \`rails/tailwind\` for stack intersections)
3. Check if that note already exists by calling \`memory-recall\` with relevant keywords
4. If the note exists and the info is new, call \`memory-save\` with action \`append\`
5. If the note doesn't exist, call \`memory-save\` with action \`create\`
6. Report back what was saved and where

Only save genuinely durable preferences — not task-specific instructions.`

export default (async () => ({
  tool: {
    "memory-recall": memoryRecall,
    "memory-save": memorySave,
  },
  config: async (config: Record<string, any>) => {
    config.command ??= {}
    config.command["memory"] = {
      description: "Review conversation for preferences to save to LLM Notes vault",
      model: "anthropic/claude-haiku-4-5",
      subtask: true,
      template: MEMORY_COMMAND_TEMPLATE,
    }
  },
  "experimental.chat.system.transform": async (_input: unknown, output: { system: string[] }) => {
    output.system.push(MEMORY_SYSTEM_INSTRUCTIONS)
  },
})) satisfies Plugin
