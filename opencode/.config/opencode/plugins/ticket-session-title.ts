/**
 * Ticket Session Title Plugin
 *
 * Automatically renames the OpenCode session when a ticket is claimed
 * (tk start <id> or tk status <id> in_progress). Extracts the ticket
 * ID and title from `tk show` output and sets it as the session title.
 *
 * Only activates in projects that have a .tickets directory.
 */
export const TicketSessionTitle = async ({ client, $ }) => {
  return {
    "tool.execute.after": async (input, _output) => {
      if (input.tool !== "bash") return

      const cmd = input.args?.command || ""

      // Match: tk start <id>
      // Match: tk status <id> in_progress
      // Handles short IDs (1z29) and full IDs (par-1z29)
      // Works with mise exec prefix and command chains (&&, ;)
      const claimMatch =
        cmd.match(/tk\s+start\s+([\w-]+)/) ||
        cmd.match(/tk\s+status\s+([\w-]+)\s+in_progress/)
      if (!claimMatch) return

      // Only activate in projects that use the ticket tool
      try {
        await $`test -d .tickets`.quiet()
      } catch {
        return
      }

      const ticketId = claimMatch[1]

      try {
        const result = await $`tk show ${ticketId}`.text()

        // Parse the ticket ID from YAML frontmatter
        const idMatch = result.match(/^id:\s*(.+)$/m)
        // Parse the title from the first markdown heading
        const titleMatch = result.match(/^#\s+(.+)$/m)
        if (!idMatch || !titleMatch) return

        const title = `${idMatch[1].trim()}: ${titleMatch[1].trim()}`

        await client.session.update({
          path: { id: input.sessionID },
          body: { title },
        })
      } catch {
        // Silently fail - don't break the workflow
      }
    },
  }
}
