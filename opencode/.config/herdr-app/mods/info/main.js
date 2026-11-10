// The active space at a glance: its ticket, the ticket's PRs, where its work runs.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, panes, exec, theme, window } from "herdr";

const DEFAULT_BRANCHES = new Set(["main", "master"]);
const EVERY = 2 * 60000;
const RETRY = 30000;
const ICON = (name) => `mods/info/${name}.svg`;
const CHROME = (name) => `mods/workspace-chrome/${name}.svg`;
const FAILED = new Set(["FAILURE", "ERROR", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"]);
const PENDING = new Set(["IN_PROGRESS", "QUEUED", "PENDING", "WAITING", "REQUESTED", "EXPECTED"]);
const SESSION = /https:\/\/claude\.ai\/code\/session_[A-Za-z0-9]+/g;
const PR_FIELDS = "number,title,state,isDraft,url,headRefName,baseRefName,additions,deletions,reviewDecision,statusCheckRollup,body";

const openUrl = (url) => exec("open", [url]).catch(() => {});

// The same texts project-tree looks a space's ticket up by: its name if someone
// named it, and its first branch off the default one.
function lookup() {
  const space = spaces().find((s) => s.active);
  if (!space) return null;
  const tabs = new Set((space.tabs ?? []).map((c) => c.id));
  const ps = panes().filter((p) => tabs.has(p.tab) && p.cwd);
  const pane = ps.find((p) => p.branch && !DEFAULT_BRANCHES.has(p.branch));
  const texts = [space.named ? space.name : null, pane?.branch].filter(Boolean);
  const on = space.machine ?? null;
  const folders = [...new Set(ps.map((p) => p.cwd))];
  return { key: JSON.stringify([on, ...texts]), on, cwd: pane?.cwd ?? folders[0] ?? space.folder, texts, folders };
}

async function json(cmd, args, opts) {
  try {
    const r = await exec(cmd, args, opts);
    return r.code === 0 ? JSON.parse(r.stdout) : null;
  } catch {
    return null;
  }
}

// Stack order: from each PR whose base is no other PR's head, along base -> head.
function stacked(prs) {
  const heads = new Set(prs.map((p) => p.headRefName));
  const out = [];
  const walk = (base) => {
    for (const p of prs.filter((x) => x.baseRefName === base).sort((a, b) => a.number - b.number)) {
      out.push(p);
      walk(p.headRefName);
    }
  };
  for (const base of new Set(prs.filter((p) => !heads.has(p.baseRefName)).map((p) => p.baseRefName))) walk(base);
  return out;
}

// GitHub counts only each check's newest run; the rollup keeps superseded ones too
// (a run cancelled by a newer push fails its summary job).
function checks(pr) {
  const started = (c) => c.startedAt || "￿"; // queued: not started, but newest
  const latest = new Map();
  for (const c of pr.statusCheckRollup ?? []) {
    const name = c.context ?? `${c.workflowName}/${c.name}`;
    if (!latest.has(name) || started(c) > started(latest.get(name))) latest.set(name, c);
  }
  let failing = 0, running = 0;
  for (const c of latest.values()) {
    if (FAILED.has(c.conclusion ?? c.state)) failing++;
    else if (PENDING.has(c.status ?? c.state)) running++;
  }
  return { failing, running };
}

function worktrees(text) {
  return text.split(/\n\n+/).map((block) => {
    const lines = block.split("\n");
    return {
      path: lines.find((l) => l.startsWith("worktree "))?.slice(9),
      branch: lines.find((l) => l.startsWith("branch "))?.slice(7).replace(/^refs\/heads\//, ""),
    };
  }).filter((w) => w.path);
}

export default class Info extends View {
  init(_props, cx) {
    this.data = {}; // key -> { ticket, prs, previews, sessions, at }
    this.busy = new Set();
    cx.timer.every(EVERY, (cx) => {
      const want = lookup();
      if (want?.texts.length && window().active) this.refresh(want, cx, true);
    });
  }

  refresh(want, cx, force = false) {
    const seen = this.data[want.key];
    // A miss can be a hiccup (a machine away, a slow tracker): ask again soon.
    const fresh = seen && (seen.ticket || Date.now() - seen.at < RETRY);
    if (this.busy.has(want.key) || (!force && fresh)) return;
    this.busy.add(want.key);
    cx.spawn(async (cx) => {
      const { on, cwd, texts, folders } = want;
      const ticket = await json("get-ticket", ["-C", cwd, ...texts], { on, timeout: 30000 });
      const id = ticket?.id?.toLowerCase();
      const [found, list] = await Promise.all([
        id ? json("gh", ["pr", "list", "--state", "all", "--search", ticket.id, "--limit", "50", "--json", PR_FIELDS], { cwd, on, timeout: 30000 }) : null,
        exec("git", ["worktree", "list", "--porcelain"], { cwd, on }).then((r) => (r.code === 0 ? worktrees(r.stdout) : [])).catch(() => []),
      ]);
      const prs = stacked((found ?? []).filter((p) => id && p.headRefName.toLowerCase().includes(id)));
      const dirs = [...new Set([...folders, ...list.filter((w) => id && w.branch?.toLowerCase().includes(id)).map((w) => w.path)])];
      const previews = (await Promise.all(dirs.map((d) => json("get-preview", ["-C", d], { on, timeout: 10000 })))).filter(Boolean);
      const sessions = [...new Set(prs.flatMap((p) => p.body?.match(SESSION) ?? []))];
      this.data[want.key] = {
        ticket,
        prs,
        previews: [...new Map(previews.map((p) => [p.url, p])).values()],
        sessions,
        at: Date.now(),
      };
      this.busy.delete(want.key);
      cx.notify();
    });
  }

  section(title, rows, t) {
    return v_flex().gap(2).child(div().px(14).pt(12).pb(4).text_size(11.5).text_color(t.dim).child(title)).children(rows);
  }

  ticketRow(ticket, t) {
    return h_flex().id("info-ticket").mx(6).px(8).py(6).gap(8).items_center().rounded(7).hover((s) => s.bg(t.hover))
      .when(Boolean(ticket.url), (el) => el.cursor_pointer().tooltip(ticket.url).on_click(() => openUrl(ticket.url)))
      .child(div().flex_none().px(5).h(17).rounded(4).flex().items_center().text_size(10.5).font_semibold().bg(t.accent + "22").text_color(t.accent).child(ticket.id))
      .child(div().flex_1().min_w(0).truncate().child(ticket.title ?? ""))
      .when(Boolean(ticket.status), (el) => el.child(div().flex_none().text_size(11).text_color(t.muted).child(ticket.status)));
  }

  prIcon(pr, t) {
    const [icon, color, word] = pr.state === "MERGED" ? ["git-merge", t.ansi5, "Merged"]
      : pr.state === "CLOSED" ? ["git-pull-request-closed", t.ansi1, "Closed"]
      : pr.isDraft ? ["circle-dashed", t.muted, "Draft"]
      : pr.reviewDecision === "APPROVED" ? ["circle-check", t.ansi2, "Approved"]
      : pr.reviewDecision === "CHANGES_REQUESTED" ? ["circle-x", t.ansi1, "Changes requested"]
      : ["git-pull-request", t.muted, "Review required"];
    const path = icon === "circle-check" ? CHROME(icon) : ICON(icon);
    return div().id(`pr-icon-${pr.number}`).flex_none().pt(1).tooltip(word).child(svg(path).size(15).text_color(color));
  }

  prRow(pr, t) {
    const { failing, running } = checks(pr);
    const repo = pr.url.split("/")[4] ?? "";
    return h_flex().id(`pr-${pr.number}`).mx(6).px(8).py(6).gap(9).items_start().rounded(7).cursor_pointer()
      .hover((s) => s.bg(t.hover)).tooltip(pr.headRefName).on_click(() => openUrl(pr.url))
      .child(this.prIcon(pr, t))
      .child(v_flex().flex_1().min_w(0).gap(2)
        .child(div().truncate().text_color(t.foreground).child(pr.title))
        .child(h_flex().gap(6).items_center().text_size(12)
          .child(div().text_color(t.dim).child(`${repo} #${pr.number}`))
          .child(div().text_color(t.ansi2).child(`+${pr.additions}`))
          .child(div().text_color(t.ansi1).child(`−${pr.deletions}`))
          .child(div().flex_1())
          .when(failing > 0, (el) => el.child(div().text_color(t.ansi1).child(`${failing} failing`)))
          .when(!failing && running > 0, (el) => el.child(svg(CHROME("spinner")).size(11).text_color(t.working).spin(900)).child(div().text_color(t.muted).child("running")))));
  }

  linkRow(id, label, url, dot, t) {
    return h_flex().id(id).mx(6).px(8).py(6).gap(8).items_center().rounded(7).cursor_pointer().hover((s) => s.bg(t.hover))
      .tooltip(url).on_click(() => openUrl(url))
      .child(div().size(7).flex_none().rounded(4).bg(dot))
      .child(div().flex_none().text_color(t.muted).child(label))
      .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(url.replace(/^https:\/\//, "")));
  }

  render(cx) {
    const t = theme();
    const want = lookup();
    if (want?.texts.length) this.refresh(want, cx);
    const data = want ? this.data[want.key] : null;
    const empty = !want?.texts.length || (data && !data.ticket && !data.previews.length) ? "No ticket for this space" : !data ? "Loading…" : null;
    const envs = data ? [
      ...data.previews.map((p, i) => this.linkRow(`preview-${i}`, "Local", p.url, p.running ? t.ansi2 : t.dim, t)),
      ...data.sessions.map((url, i) => this.linkRow(`session-${i}`, "Claude", url, t.accent, t)),
    ] : [];
    return v_flex().id("info").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).items_center().border_b(1).border_color(t.border).child(div().font_semibold().child("Info")))
      .when(Boolean(empty), (el) => el.child(div().p(14).text_color(t.dim).child(empty)))
      .when(Boolean(data) && !empty, (el) => el.child(v_flex().id("info-scroll").flex_1().min_h(0).overflow_y_scrollbar().pb(12)
        .when(Boolean(data.ticket), (el) => el.child(this.section("Ticket", [this.ticketRow(data.ticket, t)], t)))
        .when(data.prs.length > 0, (el) => el.child(this.section("Pull requests", data.prs.map((pr) => this.prRow(pr, t)), t)))
        .when(envs.length > 0, (el) => el.child(this.section("Environments", envs, t)))));
  }
}
