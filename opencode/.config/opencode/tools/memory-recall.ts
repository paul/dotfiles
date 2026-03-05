import { tool } from "@opencode-ai/plugin"
import path from "path"

const VAULT = "LLM Notes"
const TOKEN_SUMMARIZE_THRESHOLD = 2000
const MAX_NOTES = 10

/** Rough token estimate: ~4 chars per token */
function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

/** Run an obsidian CLI command and return stdout */
async function obsidian(...args: string[]): Promise<string> {
  const result = await Bun.$`obsidian ${args} vault=${VAULT}`.text()
  return result.trim()
}

/**
 * Given a list of all vault tags and a set of query keywords/tags,
 * return the matching tags using the following rules:
 *
 *   1. Simple match: query keyword == tag  (e.g. "rails" matches #rails)
 *   2. Compound match: compound tag whose parts are ALL present in the query
 *      (e.g. "rails/tailwind" matches when both "rails" and "tailwind" are queried)
 *
 * Tags are stored without the leading "#".
 */
function matchTags(allTags: string[], queryTerms: string[]): string[] {
  const terms = queryTerms.map((t) => t.toLowerCase().replace(/^#/, ""))
  const matched: string[] = []

  for (const tag of allTags) {
    const t = tag.toLowerCase().replace(/^#/, "")
    if (t.includes("/")) {
      // Compound tag: all parts must be present in query terms
      const parts = t.split("/")
      if (parts.every((p) => terms.includes(p))) {
        matched.push(t)
      }
    } else {
      // Simple tag: direct match
      if (terms.includes(t)) {
        matched.push(t)
      }
    }
  }

  return matched
}

export default tool({
  description:
    "Retrieve relevant notes from the LLM Notes Obsidian vault. " +
    "Call this at the start of a task to load personal preferences, " +
    "project conventions, and stack-specific instructions. " +
    "Pass keywords describing the current task and stack (e.g. ['rails', 'tailwind', 'css']).",
  args: {
    keywords: tool.schema
      .array(tool.schema.string())
      .describe(
        "Keywords describing the current task and stack. Include framework names, " +
          "library names, topic areas, and project name if known. " +
          "E.g. ['rails', 'tailwind', 'css', 'paramaker']"
      ),
    task_description: tool.schema
      .string()
      .optional()
      .describe(
        "Brief description of the current task, used for summarization when many notes are retrieved."
      ),
  },
  async execute(args, context) {
    const { keywords, task_description } = args

    // 1. Fetch all tags in the vault
    let allTagsRaw: string
    try {
      allTagsRaw = await obsidian("tags", "format=json")
    } catch (e) {
      return `Memory recall failed: could not reach Obsidian vault "${VAULT}". Is Obsidian running? Error: ${e}`
    }

    let allTags: { tag: string }[]
    try {
      allTags = JSON.parse(allTagsRaw)
    } catch {
      return `Memory recall failed: could not parse tags response: ${allTagsRaw}`
    }

    const tagNames = allTags.map((t) => t.tag.replace(/^#/, ""))

    // 2. Match tags against query keywords
    const matchedTags = matchTags(tagNames, keywords)

    if (matchedTags.length === 0) {
      return `No matching notes found in "${VAULT}" for keywords: ${keywords.join(", ")}. ` +
        `Available tags: ${tagNames.join(", ")}`
    }

    // 3. Collect files for each matched tag (deduplicated)
    const fileSet = new Set<string>()
    for (const tag of matchedTags) {
      try {
        const result = await obsidian("tag", `name=${tag}`, "verbose")
        // Output format: "#tagname\tN\nfile1\nfile2\n..."
        const lines = result.split("\n").slice(1) // skip header line
        for (const line of lines) {
          const f = line.trim()
          if (f) fileSet.add(f)
        }
      } catch {
        // Tag might have no files, skip
      }
    }

    if (fileSet.size === 0) {
      return `Tags matched (${matchedTags.join(", ")}) but no notes found under those tags.`
    }

    // 4. Read notes, cap at MAX_NOTES
    // Prioritize: compound-tagged notes first (more specific), then simple
    const allFiles = Array.from(fileSet)
    const prioritized = allFiles.sort((a, b) => {
      // Notes matched by compound tags come first
      const aCompound = matchedTags.some((t) => t.includes("/"))
      const bCompound = matchedTags.some((t) => t.includes("/"))
      if (aCompound && !bCompound) return -1
      if (!aCompound && bCompound) return 1
      return 0
    })
    const filesToRead = prioritized.slice(0, MAX_NOTES)

    const noteContents: { file: string; content: string }[] = []
    for (const file of filesToRead) {
      try {
        const content = await obsidian("read", `path=${file}`)
        noteContents.push({ file, content })
      } catch {
        // File might have moved or been deleted
      }
    }

    if (noteContents.length === 0) {
      return `Could not read any notes from vault "${VAULT}".`
    }

    // 5. Build combined output
    const combined = noteContents
      .map((n) => `### ${n.file}\n\n${n.content}`)
      .join("\n\n---\n\n")

    const totalTokens = estimateTokens(combined)

    // 6. Return summary metadata so the plugin can track what was injected
    const header =
      `<!-- memory-recall: matched_tags=${matchedTags.join(",")} ` +
      `files=${filesToRead.join("|")} tokens=${totalTokens} -->\n\n`

    if (totalTokens <= TOKEN_SUMMARIZE_THRESHOLD) {
      // Under threshold: return raw notes
      return (
        header +
        `## Personal Notes & Preferences\n` +
        `*Retrieved from LLM Notes vault (${noteContents.length} notes, ~${totalTokens} tokens)*\n\n` +
        combined
      )
    }

    // Over threshold: ask caller (the main LLM) to be aware there are many notes.
    // The memory-summarizer agent handles condensing when invoked via Task tool.
    return (
      header +
      `## Personal Notes & Preferences\n` +
      `*Retrieved from LLM Notes vault (${noteContents.length} notes, ~${totalTokens} tokens — consider using @memory-summarizer to condense)*\n\n` +
      combined
    )
  },
})
