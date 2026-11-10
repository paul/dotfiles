// A new space from a ticket or a few words about the work, with opencode in it and
// `/start <input>` in its prompt, not sent. Lookups run on the space's machine.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { props, closeOverlay, theme, exec, hc } from "herdr";

const NAME = `Turn this description of coding work into a 1-5 word label for a sidebar. Keep domain words; drop filler like "update", "add", "fix the". Reply with only the label: no quotes, no trailing period.\n\n`;
// `hc keys` presses unshifted keys only: other symbols can't be typed.
const TYPEABLE = /^[a-z0-9\-,.'\/;=\[\]\\`]$/;

function keysFor(text) {
  return [...text].flatMap((c) => (c === " " ? ["space"] : /[A-Z]/.test(c) ? [`shift+${c.toLowerCase()}`] : TYPEABLE.test(c) ? [c] : []));
}

// A 1-5 word name for the work, or null. Runs in the project's folder so opencode uses
// that project's model; the session it makes is deleted.
async function name(text, on, cwd) {
  let reply = "", session = null;
  try {
    const r = await exec("opencode", ["run", "--format", "json", "--title", "herdr label", NAME + text], { cwd, on, timeout: 60000 });
    for (const line of r.stdout.split("\n")) {
      try {
        const e = JSON.parse(line);
        session ??= e.sessionID ?? null;
        if (e.type === "text" && e.part?.text) reply = e.part.text;
      } catch {}
    }
  } catch {}
  if (session) exec("opencode", ["session", "delete", session], { cwd, on }).catch(() => {});
  const label = reply.trim().split("\n").pop().trim().replace(/^["'`]+|["'`.]+$/g, "");
  const words = label.split(/\s+/).filter(Boolean).length;
  return words >= 1 && words <= 5 && label.length <= 40 ? label : null;
}

// The ticket the input names, for the tracker this repo declares, else null.
async function ticket(text, on, cwd) {
  try {
    const r = await exec("get-ticket", ["-C", cwd, text], { on, timeout: 30000 });
    return r.code === 0 ? JSON.parse(r.stdout) : null;
  } catch { return null; }
}

export default class SpaceStart extends View {
  init(_props, cx) {
    this.text = "";
    this.busy = null;
    this.error = null;
    this.input = InputState.new({ value: "" });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); cx.notify(); });
    this.input.on("submit", (_e, cx) => this.submit(cx));
    this.inputFocused = true;
    this.input.on("focus", (_e, cx) => { this.inputFocused = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.inputFocused = false; cx.notify(); });
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
  }

  submit(cx) {
    const input = this.text.trim().replace(/\s+/g, " ");
    if (!input || this.busy) return;
    const { folder, machine, overlay } = props();
    const on = machine || undefined;
    this.busy = "Looking it up…";
    this.error = null;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        // A space named just its ticket id: the project tree shows that ticket's short title.
        const found = await ticket(input, on, folder);
        if (!found) { this.busy = "Naming…"; cx.notify(); }
        const title = found?.id ?? (await name(input, on, folder)) ?? input.split(" ").slice(0, 5).join(" ");
        this.busy = "Starting opencode…";
        cx.notify();
        const r = await exec("herdr-app", ["do", "space.new", "--name", title, "--folder", folder, "--machine", machine ?? "", "--argv", JSON.stringify(["opencode"])]);
        let made = null;
        try { made = JSON.parse(r.stdout); } catch {}
        if (!made?.terminal) throw new Error(made?.error || r.stderr.trim() || "Couldn't make the space.");
        // opencode reports idle before its prompt takes keys; the placeholder means it does.
        await hc(["wait", made.terminal, "--output", "Ask anything", "--timeout", "20"]);
        await hc(["keys", made.terminal, ...keysFor(`/start ${input}`)]);
        closeOverlay(overlay);
      } catch (e) {
        this.error = String(e.message ?? e);
        this.busy = null;
        cx.notify();
      }
    });
  }

  key(e, cx) {
    if (e.key === "escape") { closeOverlay(props().overlay); cx.stop_propagation(); }
  }

  render() {
    const t = theme();
    const p = props() ?? {};
    const hint = this.error ?? this.busy ?? `Starts opencode in ${p.folder}${p.machine ? ` on ${p.machine}` : ""}.`;
    const button = (id, text, primary, action) => h_flex().id(id).h(32).px(14).items_center().rounded(8)
      .border_1().border_color(primary ? t.solid : t.input).bg(primary ? t.solid : t.raised)
      .text_color(primary ? t.solid_foreground : t.foreground).text_size(12.5).font_medium().cursor_pointer()
      .when(primary && Boolean(this.busy), (el) => el.opacity(0.5))
      .hover((s) => s.opacity(0.88)).on_click(action).child(text);
    return v_flex().id("space-start").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .w_full().min_h(0).p(18).bg(t.popover).text_color(t.foreground)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child(p.title ?? "New space"))
        .child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().pt(16).pb(7).text_size(11.5).text_color(t.dim).child("Ticket, or what you'll work on"))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(this.inputFocused ? t.accent : t.input).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(div().pt(6).text_size(11.5).text_color(this.error ? t.blocked : t.dim).truncate().child(hint))
      .child(h_flex().pt(20).gap(8).justify_end()
        .child(button("ss-cancel", "Cancel", false, () => closeOverlay(p.overlay)))
        .child(button("ss-start", "Start", true, (_e, cx) => this.submit(cx))));
  }
}
