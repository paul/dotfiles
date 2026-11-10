// The active space's ticket, whole: get-ticket --full on the space's machine, as markdown.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { spaces, panes, exec, theme, window } from "herdr";

const DEFAULT_BRANCHES = new Set(["main", "master"]);
const EVERY = 5 * 60000;

// The same texts project-tree looks a space's ticket up by: its name if someone
// named it, and its first branch off the default one.
function lookup() {
  const space = spaces().find((s) => s.active);
  if (!space) return null;
  const tabs = new Set((space.tabs ?? []).map((c) => c.id));
  const ps = panes().filter((p) => tabs.has(p.tab) && p.cwd);
  const pane = ps.find((p) => p.branch && !DEFAULT_BRANCHES.has(p.branch));
  const texts = [space.named ? space.name : null, pane?.branch].filter(Boolean);
  const cwd = pane?.cwd ?? ps[0]?.cwd ?? space.folder;
  const on = space.machine ?? null;
  return { key: JSON.stringify([on, ...texts]), on, cwd, texts };
}

function markdown(ticket) {
  const comments = (ticket.comments ?? []).map((c) =>
    `**${c.author ?? "Someone"}** · ${(c.created ?? "").slice(0, 10)}\n\n${c.body ?? ""}`);
  return [ticket.body || "_No description._", ...(comments.length ? ["---", ...comments] : [])].join("\n\n");
}

export default class Ticket extends View {
  init() {
    this.results = {}; // key -> { ticket, error, at }
    this.busy = new Set();
  }

  fetch(want, cx) {
    if (this.busy.has(want.key)) return;
    const seen = this.results[want.key];
    if (seen && (!window().active || Date.now() - seen.at < EVERY)) return;
    this.busy.add(want.key);
    cx.spawn(async (cx) => {
      const result = { ticket: null, error: null, at: Date.now() };
      try {
        const r = await exec("get-ticket", ["-C", want.cwd, "--full", ...want.texts], { on: want.on, timeout: 60000 });
        if (r.code === 0) result.ticket = JSON.parse(r.stdout);
        else if (r.code !== 1) result.error = r.stderr.trim() || `get-ticket exited ${r.code}`;
      } catch (e) {
        result.error = String(e.message ?? e);
      }
      this.results[want.key] = seen?.ticket && result.error ? { ...seen, at: result.at } : result;
      this.busy.delete(want.key);
      cx.notify();
    });
  }

  render(cx) {
    const t = theme();
    const want = lookup();
    if (want?.texts.length) this.fetch(want, cx);
    const result = want ? this.results[want.key] : null;
    const ticket = result?.ticket;
    const empty = !want?.texts.length ? "No ticket for this space"
      : !result ? "Loading…"
      : result.error ?? (ticket ? null : "No ticket for this space");
    return v_flex().id("ticket").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Ticket"))
        .when(Boolean(ticket), (el) => el
          .child(div().id("ticket-id").flex_none().px(5).h(17).rounded(4).flex().items_center().text_size(10.5).font_semibold()
            .bg(t.accent + "22").text_color(t.accent).hover((s) => s.bg(t.accent + "40"))
            .when(Boolean(ticket.url), (el) => el.cursor_pointer().tooltip(ticket.url).on_click(() => exec("open", [ticket.url]).catch(() => {})))
            .child(ticket.id))
          .child(div().flex_1())
          .when(Boolean(ticket.status), (el) => el.child(div().flex_none().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(ticket.status)))))
      .when(Boolean(empty), (el) => el.child(div().p(14).text_color(t.dim).child(empty)))
      .when(Boolean(ticket), (el) => el.child(v_flex().id("ticket-scroll").flex_1().min_h(0).overflow_y_scrollbar().p(14).gap(10)
        .child(div().text_size(15).font_semibold().child(ticket.title ?? ""))
        .child(TextView.markdown(`ticket-body-${ticket.id}`, markdown(ticket)).selectable(true))));
  }
}
