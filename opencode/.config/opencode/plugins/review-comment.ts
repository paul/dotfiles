import { Plugin } from "@opencode/plugin";
import { execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

const DEFAULT_AUTHOR = "Review Agent";
const SEVERITIES = ["critical", "major", "minor", "nit"] as const;
type Severity = (typeof SEVERITIES)[number];
// The filename prefixes code-review.nvim uses when status_management is on.
const STATUSES = ["action-required", "waiting-review", "resolved"] as const;
type Status = (typeof STATUSES)[number];

// Mirrors find_project_root() in ~/.config/nvim/lua/plugins/ai.lua so both
// sides agree on where .code-review lives, even across git worktrees (whose
// .git is a file, not a dir, so naive directory walks miss it).
function findWorktreeRoot(startDir: string): string {
  try {
    const out = execFileSync("git", ["-C", startDir, "rev-parse", "--show-toplevel"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    if (out) return out;
  } catch {
    // not a git repo, or git unavailable
  }
  let dir = startDir;
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, ".git"))) return dir;
    dir = path.dirname(dir);
  }
  return startDir;
}

function formatTimestamp(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
  );
}

function generateId(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  const ms = String(d.getMilliseconds()).padStart(3, "0");
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}-` +
    `${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}-${ms}`
  );
}

// Accepts a thread id, a filename, or a path, with or without a status prefix.
function threadId(thread: string): string {
  const base = path
    .basename(thread)
    .replace(/\.md$/, "")
    .replace(/_thread$/, "");
  const prefix = STATUSES.find((status) => base.startsWith(`${status}_`));
  return prefix ? base.slice(prefix.length + 1) : base;
}

function contextBlock(
  absoluteFile: string,
  file: string,
  lineStart: number,
  lineEnd: number,
): string[] {
  const lines = fs
    .readFileSync(absoluteFile, "utf8")
    .split("\n")
    .slice(lineStart - 1, lineEnd);
  if (lines.length === 0) return [];
  return ["## Context", "", "```" + path.extname(file).slice(1), ...lines, "```", ""];
}

export default Plugin.define({
  id: "review-comment",
  async setup(ctx) {
    // The tool context carries no directory, so capture the plugin's location.
    const directory = ctx.location.directory;

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "review_comment",
        description:
          "Post an inline code review comment for a specific file and line range. " +
          "The comment starts a new thread in .code-review in the file's git worktree root " +
          "(code-review.nvim integration) so it appears as an inline annotation in the editor. " +
          "Always returns the finding as text regardless.",
        input: {
          type: "object",
          properties: {
            file: {
              type: "string",
              description:
                "File path relative to the project root, or an absolute path, e.g. src/cli.rs",
            },
            line_start: {
              type: "integer",
              minimum: 1,
              description: "Starting line number of the finding",
            },
            line_end: {
              type: "integer",
              minimum: 1,
              description: "Ending line number (same as line_start for single-line findings)",
            },
            severity: {
              type: "string",
              enum: [...SEVERITIES],
              description: "Finding severity: critical | major | minor | nit",
            },
            comment: {
              type: "string",
              description: "The review comment text",
            },
            author: {
              type: "string",
              description: `Comment author, e.g. "Review Agent" or "Simplify Agent". Default: ${DEFAULT_AUTHOR}`,
            },
            status: {
              type: "string",
              enum: [...STATUSES],
              description:
                "Thread status: action-required (the builder acts next, default) | " +
                "waiting-review (the user acts next) | resolved",
            },
          },
          required: ["file", "line_start", "line_end", "severity", "comment"],
          additionalProperties: false,
        },
        options: { codemode: false },
        async execute(args) {
          const { file, line_start, line_end, severity, comment } = args as {
            file: string;
            line_start: number;
            line_end: number;
            severity: Severity;
            comment: string;
          };
          const author = (args as { author?: string }).author || DEFAULT_AUTHOR;
          const status = (args as { status?: Status }).status || "action-required";
          const severityLabel = severity.charAt(0).toUpperCase() + severity.slice(1);
          const lineRef = line_start === line_end ? `${line_start}` : `${line_start}-${line_end}`;
          const inlineSummary = `- [${severityLabel}] ${file}:${lineRef}: ${comment}`;

          const absoluteFile = path.resolve(directory, file);
          if (!fs.existsSync(absoluteFile)) {
            return {
              content: `${inlineSummary}\n  ↳ not persisted: file not found at ${absoluteFile}`,
            };
          }

          const reviewDir = path.join(findWorktreeRoot(path.dirname(absoluteFile)), ".code-review");
          fs.mkdirSync(reviewDir, { recursive: true });

          const now = new Date();
          const timestamp = formatTimestamp(now);
          const id = generateId(now);
          const filename = `${status}_${id}.md`;

          const content = [
            "---",
            `file: ${file}`,
            `line_start: ${line_start}`,
            `line_end: ${line_end}`,
            `time: ${timestamp}`,
            `author: ${author}`,
            `thread_id: ${id}_thread`,
            "---",
            "",
            ...contextBlock(absoluteFile, file, line_start, line_end),
            "## Comments",
            "",
            `### ${author} - ${timestamp}`,
            "",
            `**${severityLabel}**: ${comment}`,
          ].join("\n");

          fs.writeFileSync(path.join(reviewDir, filename), content, "utf8");

          return { content: `${inlineSummary}\n  ↳ written to .code-review/${filename}` };
        },
      });

      editor.add({
        name: "review_reply",
        description:
          "Reply to a code review thread in .code-review and set the thread's status. " +
          "The reply appears in the thread in code-review.nvim.",
        input: {
          type: "object",
          properties: {
            thread: {
              type: "string",
              description:
                "The thread file name (e.g. action-required_2026-11-03-101500-123.md), or its id",
            },
            comment: {
              type: "string",
              description: "The reply text",
            },
            author: {
              type: "string",
              description: 'Reply author, e.g. "Build Agent" or "Review Agent"',
            },
            status: {
              type: "string",
              enum: [...STATUSES],
              description:
                "Thread status after the reply: action-required (the builder acts next) | " +
                "waiting-review (the user acts next) | resolved",
            },
          },
          required: ["thread", "comment", "author", "status"],
          additionalProperties: false,
        },
        options: { codemode: false },
        async execute(args) {
          const { thread, comment, author, status } = args as {
            thread: string;
            comment: string;
            author: string;
            status: Status;
          };
          const id = threadId(thread);
          const reviewDir = path.join(findWorktreeRoot(directory), ".code-review");
          const current = fs.existsSync(reviewDir)
            ? fs
                .readdirSync(reviewDir)
                .find((name) => name === `${id}.md` || name.endsWith(`_${id}.md`))
            : undefined;
          if (!current) {
            return { content: `not persisted: no thread ${id} in ${reviewDir}` };
          }

          const reply = [
            "",
            "",
            "---",
            "",
            `### ${author} - ${formatTimestamp(new Date())}`,
            "",
            comment,
          ];
          const currentPath = path.join(reviewDir, current);
          const content =
            fs.readFileSync(currentPath, "utf8").replace(/\n+$/, "") + reply.join("\n");
          const filename = `${status}_${id}.md`;

          fs.writeFileSync(path.join(reviewDir, filename), content, "utf8");
          if (filename !== current) fs.unlinkSync(currentPath);

          return { content: `replied to .code-review/${filename}` };
        },
      });
    });
  },
});
