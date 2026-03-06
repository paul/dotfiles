import { tool } from "@opencode-ai/plugin"
import { pluginConfig } from "../plugin-config"
const TOKEN_SUMMARIZE_THRESHOLD = 2000
const MAX_NOTES = 10

/** Rough token estimate: ~4 chars per token */
function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4)
}

/** Run an obsidian CLI command and return stdout */
async function obsidian(...args: string[]): Promise<string> {
  const result = await Bun.$`obsidian ${args} vault=${pluginConfig.vault}`.text()
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
    "Retrieve personal preference notes from the LLM Notes Obsidian vault. " +
    "ALWAYS call this before starting any task. " +
    "The REQUIRED `keywords` array must contain the technology stack and topic area " +
    "(e.g. ['rails', 'tailwind', 'css'] or ['rspec', 'phlex', 'testing']). " +
    "Never call this with an empty keywords array.",
  args: {
    keywords: tool.schema
      .array(tool.schema.string())
      .min(1)
      .describe(
        "REQUIRED. Technology keywords for the current task. " +
          "Include: framework (rails, angular, react), libraries (tailwind, rspec, phlex), " +
          "topic (css, testing, deployment), and project name if known (paramaker). " +
          "Example: ['rails', 'tailwind', 'css'] for a Rails+Tailwind styling task."
      ),
  },
  async execute(args, context) {
    const { keywords } = args

    // Log immediately so we can see what keywords arrived, before any async work
    context.metadata({
      title: `memory-recall: [${(keywords ?? []).join(", ") || "⚠ no keywords"}]`,
      metadata: {
        keywords: keywords ?? "undefined",
        status: "fetching vault tags...",
      },
    })

    // 1. Fetch all tags in the vault
    let allTagsRaw: string
    try {
      allTagsRaw = await obsidian("tags", "format=json")
    } catch (e) {
      context.metadata({
        title: `memory-recall: ✗ vault unreachable`,
        metadata: { error: String(e), keywords },
      })
      return `Memory recall failed: could not reach Obsidian vault "${pluginConfig.vault}". Is Obsidian running? Error: ${e}`
    }

    let allTags: { tag: string }[]
    try {
      allTags = JSON.parse(allTagsRaw)
    } catch {
      context.metadata({
        title: `memory-recall: ✗ bad tag response`,
        metadata: { raw: allTagsRaw, keywords },
      })
      return `Memory recall failed: could not parse tags response: ${allTagsRaw}`
    }

    const tagNames = allTags.map((t) => t.tag.replace(/^#/, ""))

    // 2. Match tags against query keywords
    const matchedTags = matchTags(tagNames, keywords)

    context.metadata({
      title: `memory-recall: [${keywords.join(", ")}] → ${matchedTags.length} tag(s) matched`,
      metadata: {
        keywords,
        "vault tags": tagNames,
        "matched tags": matchedTags.length > 0 ? matchedTags : "(none)",
      },
    })

    if (matchedTags.length === 0) {
      return `No matching notes found in "${pluginConfig.vault}" for keywords: ${keywords.join(", ")}. ` +
        `Available tags: ${tagNames.join(", ")}`
    }

    // 3. Collect files for each matched tag (deduplicated), tracking which
    //    tags matched each file so we can sort by specificity
    const fileTagMap = new Map<string, string[]>() // file -> tags that matched it
    for (const tag of matchedTags) {
      try {
        const result = await obsidian("tag", `name=${tag}`, "verbose")
        // Output format: "#tagname\tN\nfile1\nfile2\n..."
        const lines = result.split("\n").slice(1)
        for (const line of lines) {
          const f = line.trim()
          if (f) {
            const existing = fileTagMap.get(f) ?? []
            fileTagMap.set(f, [...existing, tag])
          }
        }
      } catch {
        // Tag might have no files, skip
      }
    }

    if (fileTagMap.size === 0) {
      return `Tags matched (${matchedTags.join(", ")}) but no notes found under those tags.`
    }

    // 4. Sort: files matched by compound tags first (more specific)
    const filesToRead = Array.from(fileTagMap.entries())
      .sort(([, aTags], [, bTags]) => {
        const aHasCompound = aTags.some((t) => t.includes("/"))
        const bHasCompound = bTags.some((t) => t.includes("/"))
        if (aHasCompound && !bHasCompound) return -1
        if (!aHasCompound && bHasCompound) return 1
        return 0
      })
      .slice(0, MAX_NOTES)
      .map(([file]) => file)

    // 5. Read note contents
    const noteContents: { file: string; content: string; tokens: number }[] = []
    for (const file of filesToRead) {
      try {
        const content = await obsidian("read", `path=${file}`)
        noteContents.push({ file, content, tokens: estimateTokens(content) })
      } catch {
        // File might have moved or been deleted
      }
    }

    if (noteContents.length === 0) {
      return `Could not read any notes from vault "${pluginConfig.vault}".`
    }

    const combined = noteContents
      .map((n) => `### ${n.file}\n\n${n.content}`)
      .join("\n\n---\n\n")

    const totalTokens = estimateTokens(combined)
    const overThreshold = totalTokens > TOKEN_SUMMARIZE_THRESHOLD

    // 6. Update metadata with full debug info now that we have results
    context.metadata({
      title: `memory-recall: ${noteContents.length} notes, ~${totalTokens} tokens`,
      metadata: {
        keywords,
        "matched tags": matchedTags,
        notes: noteContents.map((n) => ({
          file: n.file,
          tokens: `~${n.tokens}`,
          preview: n.content.replace(/^---[\s\S]*?---\n*/m, "").trim().slice(0, 120) + "…",
        })),
        "total tokens": `~${totalTokens}${overThreshold ? " ⚠ over summarization threshold" : ""}`,
      },
    })

    // 7. Build LLM-facing output
    const header =
      `<!-- memory-recall: matched_tags=${matchedTags.join(",")} ` +
      `files=${filesToRead.join("|")} tokens=${totalTokens} -->\n\n`

    const preamble = overThreshold
      ? `## Personal Notes & Preferences\n*Retrieved from LLM Notes vault (${noteContents.length} notes, ~${totalTokens} tokens — consider using @memory-summarizer to condense)*\n\n`
      : `## Personal Notes & Preferences\n*Retrieved from LLM Notes vault (${noteContents.length} notes, ~${totalTokens} tokens)*\n\n`

    return header + preamble + combined
  },
})
