import type { Plugin } from "@opencode-ai/plugin"

/**
 * Obsidian Memory Plugin
 *
 * Hooks into `chat.message` (fires when the user sends a message) to run
 * a background diff check via a cheap model. If new durable preferences are
 * detected, injects a nudge via `experimental.chat.system.transform` so the
 * main LLM asks the user about saving them.
 *
 * Also hooks `tool.execute.after` to track which notes were injected via
 * memory-recall, so the diff agent has accurate context to compare against.
 */

const MIN_WORDS_TO_CHECK = 10
const DEBOUNCE_MS = 500 // small debounce in case of rapid sends

interface PendingChange {
  type: "enhance" | "contradict"
  note_path: string
  note_tags: string[]
  summary: string
  content: string
  existing_note_conflict?: string
}

interface DiffResult {
  changes: PendingChange[]
}

interface SessionState {
  injectedNotes: string
  checkedMessageIds: Set<string>
  pendingNudge: string | null // nudge text to inject on next system transform
  diffTimer: ReturnType<typeof setTimeout> | null
}

export const ObsidianMemoryPlugin: Plugin = async ({ client }) => {
  const sessions = new Map<string, SessionState>()

  function getState(sessionId: string): SessionState {
    if (!sessions.has(sessionId)) {
      sessions.set(sessionId, {
        injectedNotes: "",
        checkedMessageIds: new Set(),
        pendingNudge: null,
        diffTimer: null,
      })
    }
    return sessions.get(sessionId)!
  }

  function wordCount(text: string): number {
    return text.trim().split(/\s+/).filter(Boolean).length
  }

  async function runDiffCheck(
    injectedNotes: string,
    conversationText: string
  ): Promise<DiffResult | null> {
    try {
      const prompt =
        `## Notes Currently In Context\n\n${injectedNotes}\n\n` +
        `## Conversation So Far\n\n${conversationText}\n\n` +
        `Did the user express any durable preferences that enhance or contradict the notes above? ` +
        `Respond with raw JSON only, no markdown fences.`

      // Spin up a short-lived session with the cheap model for the diff
      const diffSession = await client.session.create({
        body: { title: "__memory-diff__" },
      })
      const sessionId = diffSession.data?.id
      if (!sessionId) return null

      const result = await client.session.prompt({
        path: { id: sessionId },
        body: {
          parts: [{ type: "text", text: prompt }],
          model: { providerID: "anthropic", modelID: "claude-haiku-4-5" },
        },
      })

      await client.session.delete({ path: { id: sessionId } })

      const parts: any[] = (result.data as any)?.parts ?? []
      const textPart = parts.find(
        (p: any) => p.type === "text" && typeof p.text === "string"
      )
      if (!textPart) return null

      const raw = (textPart.text as string)
        .replace(/```json\n?/g, "")
        .replace(/```\n?/g, "")
        .trim()

      return JSON.parse(raw) as DiffResult
    } catch (e) {
      await client.app.log({
        body: {
          service: "obsidian-memory",
          level: "warn",
          message: `diff check failed: ${e}`,
        },
      })
      return null
    }
  }

  return {
    /**
     * Track memory-recall tool output so we know exactly what notes
     * were injected into this session.
     */
    "tool.execute.after": async (input, output) => {
      if (input.tool !== "memory-recall") return
      const state = getState(input.sessionID)
      if (output.output?.includes("memory-recall:")) {
        state.injectedNotes +=
          (state.injectedNotes ? "\n\n---\n\n" : "") + output.output
      }
    },

    /**
     * Fires when the user submits a message — the right moment to kick off
     * a background diff check against whatever notes were injected previously.
     *
     * We debounce slightly in case of multi-part sends, then run async so we
     * don't block the main LLM response.
     */
    "chat.message": async (input, output) => {
      const { sessionID, messageID } = input
      const state = getState(sessionID)

      // Nothing injected yet — nothing to diff against
      if (!state.injectedNotes) return

      // Already checked this message
      if (messageID && state.checkedMessageIds.has(messageID)) return

      // Check if the user message is substantive
      const userText = output.parts
        .filter((p: any) => p.type === "text")
        .map((p: any) => p.text ?? "")
        .join(" ")

      if (wordCount(userText) < MIN_WORDS_TO_CHECK) return

      if (messageID) state.checkedMessageIds.add(messageID)

      // Debounce
      if (state.diffTimer) clearTimeout(state.diffTimer)

      state.diffTimer = setTimeout(async () => {
        state.diffTimer = null

        try {
          // Fetch the full conversation for context richness
          const messagesResult = await client.session.messages({
            path: { id: sessionID },
          })
          const messages: any[] = messagesResult.data ?? []

          const conversationText = messages
            .map((m: any) => {
              const role = m.info.role === "user" ? "User" : "Assistant"
              const text = (m.parts ?? [])
                .filter((p: any) => p.type === "text")
                .map((p: any) => p.text ?? "")
                .join("\n")
              return text ? `**${role}**: ${text}` : null
            })
            .filter(Boolean)
            .join("\n\n")

          const diffResult = await runDiffCheck(
            state.injectedNotes,
            conversationText
          )

          if (!diffResult || diffResult.changes.length === 0) return

          // Build nudge text to inject into the system prompt on the next turn
          const changeList = diffResult.changes
            .map((c) => {
              const label =
                c.type === "contradict"
                  ? "CONTRADICTS existing note"
                  : "New preference"
              return `- [${label}] ${c.summary} → save to \`${c.note_path}\``
            })
            .join("\n")

          state.pendingNudge =
            `[Memory System] The following durable user preferences were detected ` +
            `in the conversation. At a natural break, ask the user if they'd like ` +
            `to save them to their LLM Notes vault. If yes, call \`memory-save\` ` +
            `for each one:\n${changeList}`

          await client.app.log({
            body: {
              service: "obsidian-memory",
              level: "info",
              message: `Queued nudge for ${diffResult.changes.length} changes in session ${sessionID}`,
            },
          })
        } catch (e) {
          await client.app.log({
            body: {
              service: "obsidian-memory",
              level: "error",
              message: `Background diff error: ${e}`,
            },
          })
        }
      }, DEBOUNCE_MS)
    },

    /**
     * Inject any pending nudge into the system prompt so the main LLM
     * naturally asks the user about saving preferences.
     */
    "experimental.chat.system.transform": async (input, output) => {
      if (!input.sessionID) return
      const state = getState(input.sessionID)
      if (!state.pendingNudge) return

      output.system.push(state.pendingNudge)

      // Clear after injecting — one nudge per batch of changes
      state.pendingNudge = null
    },

    /**
     * Clean up state when a session is deleted.
     */
    event: async ({ event }) => {
      if (event.type === "session.deleted") {
        const sessionId = (event.properties as any)?.id
        if (sessionId) {
          const state = sessions.get(sessionId)
          if (state?.diffTimer) clearTimeout(state.diffTimer)
          sessions.delete(sessionId)
        }
      }
    },
  }
}
