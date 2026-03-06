import { tool } from "@opencode-ai/plugin"
import { pluginConfig } from "../plugin-config"
const NOTE_SIZE_WARN_TOKENS = 500 // suggest splitting if note exceeds this

function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

async function obsidian(...args: string[]): Promise<string> {
  const result = await Bun.$`obsidian ${args} vault=${pluginConfig.vault}`.text()
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
  async execute(args, context) {
    const { action, path: notePath, tags, content, heading } = args

    // Normalize: ensure .md extension
    const filePath = notePath.endsWith(".md") ? notePath : `${notePath}.md`

    // Set initial metadata so the tool call is labeled in the UI immediately
    context.metadata({
      title: `memory-save: ${action} → ${filePath}`,
      metadata: { action, path: filePath, tags },
    })

    if (action === "create") {
      const tagList = tags.map((t) => `  - "${t}"`).join("\n")
      const fullContent = `---\ntags:\n${tagList}\n---\n\n${content}`

      try {
        await obsidian(
          "create",
          `path=${filePath}`,
          `content=${fullContent}`,
          "overwrite"
        )
        context.metadata({
          title: `memory-save: created ${filePath}`,
          metadata: {
            action: "create",
            path: filePath,
            tags,
            tokens: `~${estimateTokens(fullContent)}`,
            preview: content.trim().slice(0, 200) + (content.length > 200 ? "…" : ""),
          },
        })
        return `Created note: ${filePath} with tags: ${tags.join(", ")}`
      } catch (e) {
        return `Failed to create note: ${e}`
      }
    }

    if (action === "append") {
      let existingContent = ""
      try {
        existingContent = await obsidian("read", `path=${filePath}`)
      } catch {
        return `Note "${filePath}" does not exist. Use action "create" instead.`
      }

      const currentTokens = estimateTokens(existingContent)
      if (currentTokens > NOTE_SIZE_WARN_TOKENS) {
        context.metadata({
          title: `memory-save: ⚠ ${filePath} too large`,
          metadata: {
            action: "append",
            path: filePath,
            "current tokens": `~${currentTokens}`,
            warning: "Note exceeds size threshold — consider splitting",
          },
        })
        return (
          `Note "${filePath}" is already ~${currentTokens} tokens. ` +
          `Consider creating a more specific note (e.g. a sub-path like "${filePath.replace(".md", "")}/specifics.md") ` +
          `to keep notes focused and retrieval precise. ` +
          `If the content truly belongs here, re-call with action "append" — but only if there's no better home.`
        )
      }

      const appendText = heading
        ? `\n\n${heading}\n\n${content}`
        : `\n\n${content}`

      try {
        await obsidian("append", `path=${filePath}`, `content=${appendText}`)

        if (tags.length > 0) {
          const existingTagsRaw = await obsidian("tags", `path=${filePath}`, "format=json")
          let currentTags: { tag: string }[] = []
          try { currentTags = JSON.parse(existingTagsRaw) } catch {}
          const currentTagNames = currentTags.map((t) => t.tag.replace(/^#/, ""))
          const allTags = Array.from(new Set([...currentTagNames, ...tags]))
          await obsidian(
            "property:set",
            `path=${filePath}`,
            `name=tags`,
            `value=${allTags.join(",")}`,
            "type=list"
          )
        }

        context.metadata({
          title: `memory-save: appended to ${filePath}`,
          metadata: {
            action: "append",
            path: filePath,
            tags,
            "note tokens before": `~${currentTokens}`,
            "note tokens after": `~${estimateTokens(existingContent + appendText)}`,
            preview: content.trim().slice(0, 200) + (content.length > 200 ? "…" : ""),
          },
        })
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

      const headingPattern = heading.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      const sectionRegex = new RegExp(
        `(${headingPattern}\\n)([\\s\\S]*?)(?=\\n#{1,6} |$)`,
        "m"
      )

      if (!sectionRegex.test(existingContent)) {
        const appendText = `\n\n${heading}\n\n${content}`
        try {
          await obsidian("append", `path=${filePath}`, `content=${appendText}`)
          context.metadata({
            title: `memory-save: added section to ${filePath}`,
            metadata: { action: "replace_section", path: filePath, heading, note: "heading not found — appended as new section" },
          })
          return `Heading "${heading}" not found in "${filePath}" — appended as new section.`
        } catch (e) {
          return `Failed to append new section: ${e}`
        }
      }

      const updatedContent = existingContent.replace(sectionRegex, `$1${content}\n`)

      try {
        await obsidian("create", `path=${filePath}`, `content=${updatedContent}`, "overwrite")
        context.metadata({
          title: `memory-save: updated section in ${filePath}`,
          metadata: {
            action: "replace_section",
            path: filePath,
            heading,
            preview: content.trim().slice(0, 200) + (content.length > 200 ? "…" : ""),
          },
        })
        return `Updated section "${heading}" in note: ${filePath}`
      } catch (e) {
        return `Failed to update section: ${e}`
      }
    }

    return `Unknown action: ${action}`
  },
})
