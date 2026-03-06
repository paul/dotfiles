/** Mutable settings populated at startup. Override vault name with OBSIDIAN_VAULT env var. */
export const pluginConfig = {
  vault: process.env.OBSIDIAN_VAULT ?? "LLM Notes",
}
