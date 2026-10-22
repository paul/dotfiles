// custom hook, kept beside herdr-agent-state.js because the herdr integration
// owns that file and overwrites it when it reinstalls or updates.
//
// Adds the Herdr layout rules to the system prompt, but only inside a pane that
// herdr manages. Outside herdr the plugin registers no hooks at all.

import { Plugin } from "@opencode/plugin";

const LAYOUT = `## Herdr layout

You are running in a Herdr pane (HERDR_ENV=1).

- One Space = one piece of work. One tab = one agent session.
- Create one initial tab as a plane shell terminal for the user to have.
- Put each additional agent session in a new tab of the current Space. Never use a pane split for a second agent.
  \`herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <worktree> --label <role> --no-focus\`
  Start the agent in the returned root pane.
- Give the Space and each tab a short, meaningful name. Do not overwrite a name the user set.
- Use \`--no-focus\`. Never close a tab you did not create.

## Model choice for sessions you start

Choose the model yourself. Ask the user only when the choice is unclear.

Run \`opencode models\` and use the newest model in the family:

- Routine work from a clear plan: DeepSeek Flash (ex: \`opencode-go/deepseek-v4.1-flash\`)
- Planning, ambiguity, coordinating parallel work: newest Claude Opus (ex: \`anthropic/claude-opus-5-5\`)
- UI/UX/design: newest Claude Fable (ex: \`anthropic/claude-fable-5-1\`)
- Reviews: newest GPT Sol (ex: \`openai/gpt-6.1-sol\`); GPT Astra for complicated reviews (ex: \`openai/gpt-6-astra\`)

Use a different model for review than the one that wrote the code.
Do not use a version from memory; check \`opencode models\` before you choose.`;

function inHerdrPane() {
  return (
    process.env.HERDR_ENV === "1" &&
    !!process.env.HERDR_SOCKET_PATH &&
    !!process.env.HERDR_PANE_ID
  );
}

export default Plugin.define({
  id: "herdr.layout",
  async setup(ctx) {
    if (!inHerdrPane()) return;

    await ctx.session.hook("context", (event) => {
      event.system.push({ type: "text", text: LAYOUT });
    });
  },
});
