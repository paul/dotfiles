import { tool } from "@opencode-ai/plugin"

const VAULT = "LLM Notes"
const NOTE_SIZE_WARN_TOKENS = 500 // suggest splitting if note exceeds this

function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

async function obsidian(...args: string[]): Promise<string> {
  const result = await Bun.$`obsidian ${args} vault=${VAULT}`.text()
  return result.trim()
}

export default tool({
  description:
    "Create or update a note in the LLM Notes Obsidian vault. " +
    "Use this to persist user preferences, conventions, and instructions " +
    "that should be remembered across sessions. " +
    "If a note already exists and is getting large (>500 tokens), " +
    "consider creating a more specific sub-note instead (e.g. 'rails/testing.md' " +
    "rather than appending to 'rails.md').",
  args: {
    action: tool.schema
      .enum(["create", "append", "replace_section"])
      .describe(
        "'create' for a new note, 'append' to add to an existing note, " +
          "'replace_section' to update a specific heading in an existing note."
      ),
    path: tool.schema
      .string()
      .describe(
        "Path of the note relative to the vault root. " +
          "Use nested paths for specificity: 'rails/tailwind.md' not just 'notes.md'. " +
          "Compound notes (e.g. rails + tailwind) go under the primary framework: 'rails/tailwind.md'."
      ),
    tags: tool.schema
      .array(tool.schema.string())
      .describe(
        "Tags for this note. Use simple tags for broad topics ('rails', 'css'), " +
          "compound tags for stack intersections ('rails/tailwind'). " +
          "The note path should reflect its most specific tag."
      ),
    content: tool.schema
      .string()
      .describe(
        "The content to write. For 'create', the full note body (no frontmatter needed — tags are handled separately). " +
          "For 'append', the new section/preference to add. " +
          "For 'replace_section', the replacement content for the target heading."
      ),
    heading: tool.schema
      .string()
      .optional()
      .describe(
        "For 'replace_section': the heading to replace (e.g. '## Naming Conventions'). " +
          "For 'append': optionally place content under this heading."
      ),
  },
  async execute(args) {
    const { action, path: notePath, tags, content, heading } = args

    // Normalize: ensure .md extension
    const filePath = notePath.endsWith(".md") ? notePath : `${notePath}.md`

    if (action === "create") {
      // Build frontmatter
      const tagList = tags.map((t) => `  - "${t}"`).join("\n")
      const fullContent = `---\ntags:\n${tagList}\n---\n\n${content}`

      try {
        await obsidian(
          "create",
          `path=${filePath}`,
          `content=${fullContent}`,
          "overwrite"
        )
        return `Created note: ${filePath} with tags: ${tags.join(", ")}`
      } catch (e) {
        return `Failed to create note: ${e}`
      }
    }

    if (action === "append") {
      // First, check the current size of the note
      let existingContent = ""
      try {
        existingContent = await obsidian("read", `path=${filePath}`)
      } catch {
        // Note doesn't exist yet — fall back to create
        return `Note "${filePath}" does not exist. Use action "create" instead.`
      }

      const currentTokens = estimateTokens(existingContent)
      if (currentTokens > NOTE_SIZE_WARN_TOKENS) {
        return (
          `Note "${filePath}" is already ~${currentTokens} tokens. ` +
          `Consider creating a more specific note (e.g. a sub-path like "${filePath.replace(".md", "")}/specifics.md") ` +
          `to keep notes focused and retrieval precise. ` +
          `If the content truly belongs here, re-call with action "append" and include ` +
          `"override_size_warning": true in your reasoning — but only if there's no better home.`
        )
      }

      const appendText = heading
        ? `\n\n${heading}\n\n${content}`
        : `\n\n${content}`

      try {
        await obsidian("append", `path=${filePath}`, `content=${appendText}`)

        // Update tags if new ones supplied
        if (tags.length > 0) {
          const existingTags = await obsidian(
            "tags",
            `path=${filePath}`,
            "format=json"
          )
          let currentTags: { tag: string }[] = []
          try {
            currentTags = JSON.parse(existingTags)
          } catch {}
          const currentTagNames = currentTags.map((t) =>
            t.tag.replace(/^#/, "")
          )
          const allTags = Array.from(new Set([...currentTagNames, ...tags]))
          await obsidian(
            "property:set",
            `path=${filePath}`,
            `name=tags`,
            `value=${allTags.join(",")}`,
            "type=list"
          )
        }

        return `Appended to note: ${filePath}`
      } catch (e) {
        return `Failed to append to note: ${e}`
      }
    }

    if (action === "replace_section") {
      if (!heading) {
        return `"replace_section" requires a "heading" argument.`
      }

      let existingContent = ""
      try {
        existingContent = await obsidian("read", `path=${filePath}`)
      } catch {
        return `Note "${filePath}" does not exist. Use action "create" instead.`
      }

      // Find and replace the section under the given heading
      const headingPattern = heading.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      const sectionRegex = new RegExp(
        `(${headingPattern}\\n)([\\s\\S]*?)(?=\\n#{1,6} |$)`,
        "m"
      )

      if (!sectionRegex.test(existingContent)) {
        // Heading not found — append it as a new section
        const appendText = `\n\n${heading}\n\n${content}`
        try {
          await obsidian(
            "append",
            `path=${filePath}`,
            `content=${appendText}`
          )
          return `Heading "${heading}" not found in "${filePath}" — appended as new section.`
        } catch (e) {
          return `Failed to append new section: ${e}`
        }
      }

      const updatedContent = existingContent.replace(
        sectionRegex,
        `$1${content}\n`
      )

      // Write back via create with overwrite
      try {
        await obsidian(
          "create",
          `path=${filePath}`,
          `content=${updatedContent}`,
          "overwrite"
        )
        return `Updated section "${heading}" in note: ${filePath}`
      } catch (e) {
        return `Failed to update section: ${e}`
      }
    }

    return `Unknown action: ${action}`
  },
})
