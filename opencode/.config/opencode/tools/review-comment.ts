import { tool } from "@opencode-ai/plugin"
import { execFileSync } from "node:child_process"
import * as fs from "node:fs"
import * as path from "node:path"

const AUTHOR = "Review Agent"
const SEVERITIES = ["critical", "major", "minor", "nit"] as const
type Severity = (typeof SEVERITIES)[number]

// Mirrors find_project_root() in ~/.config/nvim/lua/plugins/ai.lua so both
// sides agree on where .code-review lives, even across git worktrees (whose
// .git is a file, not a dir, so naive directory walks miss it).
function findWorktreeRoot(startDir: string): string {
  try {
    const out = execFileSync("git", ["-C", startDir, "rev-parse", "--show-toplevel"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim()
    if (out) return out
  } catch {
    // not a git repo, or git unavailable
  }
  let dir = startDir
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, ".git"))) return dir
    dir = path.dirname(dir)
  }
  return startDir
}

function formatTimestamp(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0")
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  )
}

function generateFilename(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0")
  const ms = String(d.getMilliseconds()).padStart(3, "0")
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}-` +
    `${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}-${ms}.md`
  )
}

export default tool({
  description:
    "Post an inline code review comment for a specific file and line range. " +
    "The comment is written to .code-review in the file's git worktree root " +
    "(code-review.nvim integration) so it appears as an inline annotation in the editor. " +
    "Always returns the finding as text regardless.",
  args: {
    file: tool.schema.string().describe("File path relative to the project root, or an absolute path, e.g. src/cli.rs"),
    line_start: tool.schema.number().int().positive().describe("Starting line number of the finding"),
    line_end: tool.schema.number().int().positive().describe("Ending line number (same as line_start for single-line findings)"),
    severity: tool.schema
      .enum(SEVERITIES)
      .describe("Finding severity: critical | major | minor | nit"),
    comment: tool.schema.string().describe("The review comment text"),
  },
  async execute(args, context) {
    const { file, line_start, line_end, severity, comment } = args
    const severityLabel = severity.charAt(0).toUpperCase() + severity.slice(1)
    const lineRef = line_start === line_end ? `${line_start}` : `${line_start}-${line_end}`
    const inlineSummary = `- [${severityLabel}] ${file}:${lineRef}: ${comment}`

    const absoluteFile = path.resolve(context.directory, file)
    if (!fs.existsSync(absoluteFile)) {
      return `${inlineSummary}\n  ↳ not persisted: file not found at ${absoluteFile}`
    }

    const reviewDir = path.join(findWorktreeRoot(path.dirname(absoluteFile)), ".code-review")
    fs.mkdirSync(reviewDir, { recursive: true })

    const now = new Date()
    const timestamp = formatTimestamp(now)
    const filename = generateFilename(now)
    const id = filename.replace(/\.md$/, "")

    const content = [
      "---",
      `file: ${file}`,
      `line_start: ${line_start}`,
      `line_end: ${line_end}`,
      `time: ${timestamp}`,
      `author: ${AUTHOR}`,
      `thread_id: ${id}_thread`,
      "---",
      "",
      "## Comments",
      "",
      `### ${AUTHOR} - ${timestamp}`,
      "",
      `**${severityLabel}**: ${comment}`,
    ].join("\n")

    fs.writeFileSync(path.join(reviewDir, filename), content, "utf8")

    return `${inlineSummary}\n  ↳ written to .code-review/${filename}`
  },
})
