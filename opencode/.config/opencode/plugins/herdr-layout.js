// custom hook, kept beside herdr-agent-state.js because the herdr integration
// owns that file and overwrites it when it reinstalls or updates.
//
// Adds the Herdr pane rules to the system prompt, but only inside a pane that
// herdr manages. Outside herdr the plugin registers no hooks at all.

import { Plugin } from "@opencode/plugin";

const INSTRUCTIONS = `## Herdr layout

You are running in a herdr-core terminal ($HC_TERMINAL_ID) that the Herdr app shows as a tab.

- One Space = one piece of work. One tab = one agent session.
- Create one initial tab as a plane shell terminal for the user to have.
- \`hc get "$HC_TERMINAL_ID" --json\` shows your Space and tab IDs in \`labels["herdr.space"]\` and \`labels["herdr.tab"]\`.
- Put each additional agent session in a new tab of the current Space. Never use a pane split for a second agent.
  \`hc run --bg --no-parent --name <role> --cwd <worktree> --label herdr.space=<space-id> -- <agent command>\`
  A terminal with a Space label and no tab label opens as a new tab.
- Give the Space and each tab a short, meaningful name. Do not overwrite a name the user set.
- When you work a ticket, name your own tab with the ticket ID. The Herdr ticket panel reads it from the tab name.
  1. Get the tab ID: \`hc get "$HC_TERMINAL_ID" --json | jq -r '.labels["herdr.tab"]'\`
  2. Get its name: \`herdr-app ls | jq -r --arg t <tab-id> '.spaces[].tabs[] | select(.id == $t) | .name'\`
     A number means nobody named it. Any other name is the user's: keep it.
  3. Rename it: \`herdr-app do tab.rename --id <tab-id> --name <ticket-id>\`
- Never close a tab you did not create.

## Monitoring workers

- \`bot-run space\` prints \`{"space":...,"terminal":...}\` for the new worker.
- Monitor a worker with a background shell call: \`hc wait <terminal> --timeout 3600\`.
  It returns when the worker stops work or ends. Its exit wakes this session.
- Read the worker after a wake: \`hc read <terminal> --lines 60\`.
- Send the next prompt with \`hc send <terminal> "..." --wait --timeout 3600\`.
- Never monitor a worker with a \`sleep\` loop.

## Model choice for sessions you start

Choose the model yourself. Ask the user only when the choice is unclear.

Run \`opencode models\` and use the newest model in the family:

- Routine work from a clear plan: DeepSeek Flash (ex: \`opencode-go/deepseek-v4.1-flash\`)
- Planning, ambiguity, coordinating parallel work: newest Claude Opus (ex: \`claude-agent/opus\`)
- UI/UX/design: newest Claude Fable (ex: \`claude-agent/fable\`)
- Reviews: the newest model made by a different company, at the same strength as the model that wrote the code. Review Claude with OpenAI. Review OpenAI or DeepSeek with Claude.

Do not use a version from memory; check \`opencode models\` before you choose.`;

function inHerdrPane() {
  return !!process.env.HC_TERMINAL_ID && !!process.env.HC_TERMINAL_SOCKET;
}

export default Plugin.define({
  id: "herdr.layout",
  async setup(ctx) {
    if (!inHerdrPane()) return;

    await ctx.session.hook("context", (event) => {
      event.system.push({ type: "text", text: INSTRUCTIONS });
    });
  },
});
