// Project tree: machine → project → space → tab. A project is a git repo with all
// of its worktrees (its common git dir); spaces outside git sit under their machine.
// Each space shows its ticket (get-ticket, run on the space's machine) and its PR.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { spaces, machines, panes, agents, run, openOverlay, exec, hc, theme, shared, setShared, watchFolder, window, layout, setAgentOrder } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The sidebar's rail goes by its width, not a flag: dragging its edge narrows it too.
const narrow = () => (find(layout(), "sidebar")?.size?.px ?? Infinity) < 160;

// Where a space is now: its first terminal's live folder, else where it was made.
// `ps`: panes(), read once by the caller (each read copies every pane).
function place(s, ps) {
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
}
const RAIL_CELL = 32;
const railCell = (el) => h_flex().flex_none().justify_center().child(el);
const where = (s, ps) => JSON.stringify([s.machine ?? null, place(s, ps)]);
const base = (path) => path.replace(/\/+$/, "").split("/").pop();
const ICON = (name) => `mods/workspace-chrome/${name}.svg`;
// Changes made outside Herdr (an editor's save, a commit in another app): looked
// for this often, in repos the list shows, while the window is in front.
const FALLBACK = 60000;
const PR_EVERY = 5 * 60000;
const DEFAULT_BRANCHES = new Set(["main", "master"]);
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
const urgent = (list) => list.reduce((a, s) => ((RANK[s] ?? 0) > (RANK[a] ?? 0) ? s : a), null);

// What a stored color name looks like on an avatar (the same in every mod
// that draws space avatars): one strong color per hue, light and dark alike.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };
const PALETTE = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
const hue = (name) => MARK[PALETTE[[...name].reduce((h, c) => (h * 31 + c.charCodeAt(0)) >>> 0, 7) % PALETTE.length]];

export function glyph(status) {
  return status === "blocked" || status === "done" ? "●" : "·";
}

export function tone(t, status) {
  return t[status] ?? t.unknown;
}

const openUrl = (url) => exec("open", [url]).catch(() => {});
const WORKTREES_EVERY = 60000;
const SHORTEN = `Turn this issue title into a 2-4 word label for a sidebar. Keep domain words; drop filler like "update", "bring", "current patterns". Reply with only the label: no quotes, no trailing period.\n\n`;

// A 2-4 word label for a ticket title, or null when it can't give one. Runs in the
// project's folder so opencode uses that project's model; the session it makes is deleted.
async function shorten(title, on, cwd) {
  let text = "", session = null;
  try {
    const r = await exec("opencode", ["run", "--format", "json", "--title", "herdr label", SHORTEN + title], { cwd, on, timeout: 60000 });
    for (const line of r.stdout.split("\n")) {
      try {
        const e = JSON.parse(line);
        session ??= e.sessionID ?? null;
        if (e.type === "text" && e.part?.text) text = e.part.text;
      } catch {}
    }
  } catch {}
  if (session) exec("opencode", ["session", "delete", session], { cwd, on }).catch(() => {});
  const label = text.trim().split("\n").pop().trim().replace(/^["'`]+|["'`.]+$/g, "");
  const words = label.split(/\s+/).filter(Boolean).length;
  return words >= 1 && words <= 5 && label.length <= 40 ? label : null;
}

// `git worktree list --porcelain` as [{ path, branch }], bare entries left out.
function parseWorktrees(text) {
  const out = [];
  for (const block of text.split(/\n\n+/)) {
    const lines = block.split("\n");
    const path = lines.find((l) => l.startsWith("worktree "))?.slice(9);
    if (!path || lines.includes("bare")) continue;
    const branch = lines.find((l) => l.startsWith("branch "))?.slice(7).replace(/^refs\/heads\//, "") ?? null;
    out.push({ path, branch });
  }
  return out;
}

export default class ProjectTree extends View {
  init(_props, cx) {
    this.git = {}; // where() -> { name, branch, repo, linked }, null: not a repo
    this.checked = {}; // where() -> when it was last looked at
    this.unsure = new Set(); // where()s git couldn't answer for (a machine away)
    this.pending = new Set(); // where()s to look at next
    this.busy = {}; // pane -> an agent working or a program in front of its shell
    this.ready = {}; // machine -> its layout was readable at the last look
    this.at = {}; // space -> its where() at the last look
    this.watching = new Set(); // local repos' git folders
    this.prs = {}; // [repo, branch] -> { pr, at }
    this.prPending = new Map(); // [repo, branch] -> [machine, folder] to ask gh in
    this.worktrees = {}; // repo -> { list: [{ path, branch }], at }
    // Lookup -> get-ticket's answer, kept once found. Not found is remembered for this run
    // only, so a tracker set up later is asked on the next start.
    this.lookups = JSON.parse(localStorage.getItem("lookups") ?? "{}");
    this.shorts = JSON.parse(localStorage.getItem("shorts") ?? "{}"); // title -> short label
    this.ticketQueue = [];
    // Spaces made while this runs wait (at most a moment) for their git, so a
    // worktree appears under its project instead of jumping there.
    this.shown = new Set(spaces().map((s) => s.id));
    this.born = {};
    this.pressed = null; // space being dragged
    this.over = null; // space it would land at
    this.machines = [];
    this.reconnecting = JSON.parse(localStorage.getItem("machines.reconnecting") ?? "{}");
    for (const state of Object.values(this.reconnecting)) state.busy = false;
    this.folded = new Set(JSON.parse(localStorage.getItem("machines.folded") ?? "[]"));
    this.treeFolded = new Set(JSON.parse(localStorage.getItem("tree.folded") ?? "[]"));
    this.refreshMachines(cx);
    cx.timer.every(15000, cx => this.refreshMachines(cx));
    // `git status` walks the whole tree, on another machine a process there:
    // only when its answer could have changed (see `due`).
    cx.timer.every(250, (cx) => this.checkNew(cx));
  }

  checkNew(cx) {
    const now = Date.now();
    const sp = spaces();
    const ps = panes();
    for (const s of sp) if (!this.shown.has(s.id)) this.born[s.id] ??= now;
    const due = this.due(now, sp, ps);
    if (due.size) this.refreshGit(due, cx);
    const prs = this.duePrs(now, sp, ps);
    if (prs.length) this.refreshPrs(prs, cx);
    this.wantTickets(sp, ps, cx);
    const waiting = sp.some((s) => !this.shown.has(s.id));
    this.publishFolders(this.tree());
    if (waiting) cx.notify();
  }

  // Where a space's new tabs start (project-tabs opens them): the checkout of its
  // branch, else the project's main checkout. Published from the timer, which keeps
  // running while the sidebar is hidden.
  publishFolders(tree) {
    const out = {};
    for (const host of tree.values()) for (const p of host.projects) {
      const list = this.worktrees[p.repo]?.list ?? [];
      const main = list.find((x) => DEFAULT_BRANCHES.has(x.branch))?.path ?? JSON.parse(p.repo)[1].replace(/\/\.git$/, "");
      for (const r of p.rows) out[r.w.id] = list.find((x) => x.branch && x.branch === r.branch)?.path ?? main;
    }
    if (JSON.stringify(out) !== JSON.stringify(shared("space.folder") ?? {})) setShared("space.folder", out);
  }

  // Places whose git could have changed: new ones (a new space, a cd), where a
  // command or an agent's turn just ended (a checkout, a commit, edits), those on
  // a machine that is back, and repos in view whose fallback is due.
  due(now, sp, ps) {
    const at = {};
    for (const s of sp) at[s.id] = where(s, ps);
    const keys = new Set(Object.values(at).filter((k) => JSON.parse(k)[1]));
    const due = new Set([...keys].filter((k) => !(k in this.git)));
    for (const [id, k] of Object.entries(at)) if (this.at[id] && this.at[id] !== k && keys.has(k)) due.add(k);
    this.at = at;
    const spaceOf = {};
    for (const s of sp) for (const t of s.tabs ?? []) spaceOf[t.id] = s;
    const busy = {};
    for (const p of ps) {
      if (!p.terminal || !spaceOf[p.tab]) continue;
      busy[p.pane] = p.status === "working" || !(p.program?.shell || p.program?.agent);
      if (this.busy[p.pane] && !busy[p.pane]) due.add(at[spaceOf[p.tab].id]);
    }
    this.busy = busy;
    for (const m of machines()) {
      const ready = m.layout === "ready";
      if (ready && this.ready[m.name] === false) for (const k of keys) if (JSON.parse(k)[0] === m.name) due.add(k);
      this.ready[m.name] = ready;
    }
    if (window().active) {
      for (const k of keys) {
        const asks = this.git[k] || this.unsure.has(k);
        if (asks && !this.folded.has(JSON.parse(k)[0]) && now - (this.checked[k] ?? 0) > FALLBACK) due.add(k);
      }
    }
    return due;
  }


  // The branch a space works on: a pane of it off the default branch, else the repo's
  // worktree whose branch names the space's ticket (an agent made it with `wt switch`
  // without moving its own folder), else where its first terminal is.
  work(w, ps, g, id) {
    const tabs = new Set((w.tabs ?? []).map((c) => c.id));
    const pane = ps.find((p) => tabs.has(p.tab) && p.cwd && p.branch && !DEFAULT_BRANCHES.has(p.branch));
    if (pane) return { branch: pane.branch, cwd: pane.cwd };
    const wt = id && (this.worktrees[g.repo]?.list ?? []).find((x) => x.branch?.toLowerCase().includes(id.toLowerCase()));
    if (wt) return { branch: wt.branch, cwd: wt.path };
    return { branch: g.branch, cwd: place(w, ps) };
  }

  // A repo space's ticket and the branch it works on. The lookup asks with the space's
  // name and branch before the ticket's worktree is known, so the key stays the same
  // after an agent makes that worktree.
  resolve(w, ps, g) {
    const start = this.work(w, ps, g, null);
    const texts = [w.named ? w.name : null, DEFAULT_BRANCHES.has(start.branch) ? null : start.branch].filter(Boolean);
    const key = JSON.stringify([w.machine ?? null, g.repo, ...texts]);
    const ticket = texts.length ? this.lookups[key] ?? null : null;
    return { ...this.work(w, ps, g, ticket?.id), ticket, texts, key, cwd0: start.cwd };
  }

  // Branches off the default one whose PR wasn't asked for yet, or not for a while.
  duePrs(now, sp, ps) {
    const out = [];
    for (const s of sp) {
      const g = this.git[where(s, ps)];
      if (!g) continue;
      const wk = this.resolve(s, ps, g);
      if (!wk.branch || DEFAULT_BRANCHES.has(wk.branch)) continue;
      const key = JSON.stringify([g.repo, wk.branch]);
      if (this.prPending.has(key)) continue;
      const seen = this.prs[key];
      if (!seen || (window().active && now - seen.at > PR_EVERY)) out.push([key, JSON.stringify([s.machine ?? null, wk.cwd])]);
    }
    return out;
  }

  // Spaces whose lookup wasn't asked yet: get-ticket on the space's machine, in its repo.
  wantTickets(sp, ps, cx) {
    for (const w of sp) {
      const g = this.git[where(w, ps)];
      if (!g) continue;
      const { texts, key, cwd0 } = this.resolve(w, ps, g);
      if (!texts.length || key in this.lookups) continue;
      this.lookups[key] = undefined;
      this.ticketQueue.push({ key, on: w.machine ?? null, cwd: cwd0, texts });
    }
    if (!this.ticketQueue.length || this.fetchingTickets) return;
    this.fetchingTickets = true;
    cx.spawn(async (cx) => {
      while (this.ticketQueue.length) {
        const { key, on, cwd, texts } = this.ticketQueue.shift();
        let ticket = null;
        try {
          const r = await exec("get-ticket", ["-C", cwd, ...texts], { on, timeout: 30000 });
          if (r.code === 0) ticket = JSON.parse(r.stdout);
        } catch {}
        if (ticket?.title) {
          ticket.short = this.shorts[ticket.title] ??= await shorten(ticket.title, on, cwd);
          if (!ticket.short) delete this.shorts[ticket.title];
          localStorage.setItem("shorts", JSON.stringify(this.shorts));
        }
        this.lookups[key] = ticket;
        localStorage.setItem("lookups", JSON.stringify(Object.fromEntries(Object.entries(this.lookups).filter(([, v]) => v?.short))));
        cx.notify();
      }
      this.fetchingTickets = false;
    });
  }

  // A repo's checkouts, at most once a minute (one is made by `wt switch` outside Herdr).
  async listWorktrees(repo, cwd, on) {
    const seen = this.worktrees[repo];
    if (seen && Date.now() - seen.at < WORKTREES_EVERY) return seen.list;
    const entry = this.worktrees[repo] = { list: seen?.list ?? [], at: Date.now() };
    try {
      const r = await exec("git", ["worktree", "list", "--porcelain"], { cwd, on });
      if (r.code === 0) entry.list = parseWorktrees(r.stdout);
    } catch {}
    return entry.list;
  }

  // Where a new space of the project starts: the checkout on main/master.
  async mainCheckout(p) {
    const ps = panes();
    const row = p.rows.find((r) => DEFAULT_BRANCHES.has(r.g.branch));
    if (row) return place(row.w, ps);
    const [on, repo] = JSON.parse(p.repo);
    this.worktrees[p.repo] = null;
    const list = await this.listWorktrees(p.repo, place(p.rows[0].w, ps), on);
    return list.find((x) => DEFAULT_BRANCHES.has(x.branch))?.path ?? list[0]?.path ?? repo.replace(/\/\.git$/, "");
  }

  newSpace(p, m, cx) {
    cx.spawn(async () => {
      const folder = await this.mainCheckout(p);
      openOverlay({ mod: "space-start", kind: "dialog", width: 460, height: 230, props: {
        title: `New space in ${p.name}`,
        folder,
        machine: m ?? "",
      } });
    });
  }

  refreshPrs(list, cx) {
    for (const [key, k] of list) this.prPending.set(key, k);
    if (this.prBusy) return;
    this.prBusy = true;
    cx.spawn(async (cx) => {
      while (this.prPending.size) {
        const [key, at] = this.prPending.entries().next().value;
        const [on, cwd] = JSON.parse(at);
        const entry = this.prs[key] = { pr: this.prs[key]?.pr ?? null, at: Date.now() };
        try {
          const r = await exec("gh", ["pr", "view", "--json", "number,title,state,isDraft,url"], { cwd, on, timeout: 20000 });
          if (r.code === 0) entry.pr = JSON.parse(r.stdout);
          else if (/no pull requests found/i.test(r.stderr)) entry.pr = null;
        } catch {}
        this.prPending.delete(key);
        cx.notify();
      }
      this.prBusy = false;
    });
  }

  refreshMachines(cx) {
    cx.spawn(async cx => {
      try { const r = await hc(["machine", "ls", "--json"]); if (r.code === 0) this.machines = (JSON.parse(r.stdout).machines ?? []).filter((m) => !m.temporary); } catch {}
      cx.notify();
    });
  }

  rebuilt(machine) {
    return machine?.state === "unreachable" && /^a different core answers there \("[^"]+"\)$/.test(machine.why ?? "");
  }

  reconnect(machine, cx) {
    const name = machine.name;
    if (this.reconnecting[name]?.busy) return;
    const state = this.reconnecting[name] ??= { machine, removed: false };
    state.busy = true;
    state.error = null;
    localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
    cx.notify();
    cx.spawn(async cx => {
      try {
        const ask = async args => {
          const r = await hc([...args, "--json"]);
          if (r.code !== 0) {
            let error;
            try { error = JSON.parse(r.stdout || r.stderr).error?.message; } catch {}
            throw new Error(error || r.stderr || r.stdout || "Couldn't connect.");
          }
        };
        if (!state.removed) {
          await ask(["machine", "rm", name]);
          state.removed = true;
          localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
        }
        const args = ["machine", "add"];
        if (machine.via) args.push("--via", machine.target);
        else args.push(machine.target);
        args.push("--name", name);
        if (machine.session) args.push("--session", machine.session);
        if (machine.temporary) args.push("--temp");
        await ask(args);
        this.folded.delete(name);
        localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
        delete this.reconnecting[name];
      } catch (e) {
        state.error = String(e.message ?? e);
        state.busy = false;
      }
      localStorage.setItem("machines.reconnecting", JSON.stringify(this.reconnecting));
      this.refreshMachines(cx);
      cx.notify();
    });
  }

  // One look at a time, each place once however often it was asked for meanwhile.
  refreshGit(keys, cx) {
    for (const k of keys) this.pending.add(k);
    if (this.refreshing) return;
    this.refreshing = true;
    cx.spawn(async (cx) => {
      while (this.pending.size) {
        const keys = [...this.pending];
        this.pending.clear();
        for (const key of keys) await this.check(key, cx);
      }
      const used = new Set(Object.values(this.git).filter(Boolean).map((g) => JSON.parse(g.repo)).filter(([on]) => !on).map(([, repo]) => repo));
      for (const repo of this.watching) if (!used.has(repo)) this.watching.delete(repo);
      this.refreshing = false;
      cx.notify();
    });
  }

  // One place's git: its branch and its repo.
  async check(key, cx) {
    const [on, cwd] = JSON.parse(key);
    this.checked[key] = Date.now();
    this.unsure.delete(key);
    try {
      const r = await exec("git", ["branch", "--show-current"], { cwd, on });
      if (r.code !== 0) {
        // Only git's own "no" is remembered as no repo; anything else is asked again.
        if (!/not a git repository/i.test(r.stderr)) this.unsure.add(key);
        else this.git[key] = null;
        this.git[key] ??= null;
        return;
      }
      // The repo's common git dir names the project: the main checkout and every worktree share it.
      const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
      const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd, on });
      const repo = common.stdout.trim();
      const name = repo.endsWith("/.git") ? base(repo.slice(0, -5)) : base(repo).replace(/\.git$/, "");
      const info = { name, branch: r.stdout.trim() || null, repo: JSON.stringify([on, repo]), linked: repo !== `${top.stdout.trim()}/.git` };
      this.git[key] = info;
      await this.listWorktrees(info.repo, cwd, on);
      if (!on) this.watch(repo, cx);
    } catch {
      // Couldn't ask (the machine is away): keep the group it had, look again later.
      this.git[key] ??= null;
      this.unsure.add(key);
    }
  }

  watch(repo, cx) {
    if (this.watching.has(repo)) return;
    this.watching.add(repo);
    cx.spawn(async (cx) => {
      try {
        while (this.watching.has(repo)) {
          await watchFolder(repo);
          const mine = JSON.stringify([null, repo]);
          if (this.watching.has(repo)) this.refreshGit(Object.keys(this.git).filter((k) => this.git[k]?.repo === mine), cx);
        }
      } catch { this.watching.delete(repo); }
    });
  }

  toggle(key, cx) {
    this.treeFolded.has(key) ? this.treeFolded.delete(key) : this.treeFolded.add(key);
    localStorage.setItem("tree.folded", JSON.stringify([...this.treeFolded]));
    cx.notify();
  }

  // The space's line: its own name if someone named it (other than its repo's, or just a
  // ticket id: the badge shows that), its ticket's short title, the branch on main/master,
  // the PR title, its first named tab (an agent session's title), else the branch.
  label(w, g, branch, pr, ticket) {
    if (!g) return w.name;
    const onlyTicket = ticket && w.name.toLowerCase() === ticket.id.toLowerCase();
    if (w.named && !onlyTicket && w.name !== g.name) return w.name;
    if (ticket) return ticket.short ?? ticket.title;
    branch ??= "detached";
    if (DEFAULT_BRANCHES.has(branch)) return branch;
    return pr?.title ?? (w.tabs ?? []).find((c) => c.named)?.name ?? branch;
  }

  // machine -> { projects: [{ name, repo, rows }], loose: rows }, rows: { w, g, branch, pr, ticket }.
  tree() {
    const sp = spaces(), ps = panes();
    const ready = (w) => this.shown.has(w.id) || where(w, ps) in this.git || Date.now() - (this.born[w.id] ??= Date.now()) > 1500;
    for (const w of sp) if (!this.shown.has(w.id) && ready(w)) this.shown.add(w.id);
    const hosts = new Map();
    for (const w of sp) {
      if (!this.shown.has(w.id)) continue;
      const m = w.machine ?? null;
      if (!hosts.has(m)) hosts.set(m, { projects: new Map(), loose: [] });
      const host = hosts.get(m);
      const g = this.git[where(w, ps)] ?? null;
      if (!g) { host.loose.push({ w, g: null, branch: null, pr: null, ticket: null }); continue; }
      const { branch, ticket } = this.resolve(w, ps, g);
      const pr = branch ? this.prs[JSON.stringify([g.repo, branch])]?.pr ?? null : null;
      const row = { w, g, branch, pr, ticket };
      if (!host.projects.has(g.repo)) host.projects.set(g.repo, { name: g.name, repo: g.repo, rows: [] });
      host.projects.get(g.repo).rows.push(row);
    }
    const out = new Map();
    for (const [m, host] of hosts) {
      const projects = [...host.projects.values()].sort((a, b) => a.name.localeCompare(b.name));
      out.set(m, { projects, loose: host.loose });
    }
    return out;
  }

  // The rows, under a header per machine.
  grouped(t, collapsed, tree) {
    const remote = [...new Set([...[...tree.keys()].filter(Boolean), ...this.machines.map(m => m.name), ...Object.keys(this.reconnecting)])].sort();
    const loading = m => {
      const layout = machines().find(k => k.name === m)?.layout;
      return layout === "loading" || (!layout && this.machines.some(k => k.name === m && k.state === "connected"))
        || spaces().some(s => (s.machine ?? null) === m && !this.shown.has(s.id));
    };
    const loadingRow = m => h_flex().id(`machine-loading-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).items_center().when(collapsed, el => el.justify_center()).text_size(12).text_color(t.dim).child(collapsed ? "…" : "Loading…");
    return [null, ...remote].flatMap((m) => {
      const host = tree.get(m) ?? { projects: [], loose: [] };
      const repair = this.reconnecting[m];
      const machine = this.machines.find(k => k.name === m) ?? repair?.machine;
      const connected = !m || machine?.state === "connected";
      const rebuilt = this.rebuilt(machine) || !!repair;
      const folded = this.folded.has(m);
      const icon = svg(ICON(m ? "server" : "monitor")).size(13).flex_none();
      const badge = div().absolute().right(-3).bottom(-2).size(6).rounded(3).border_1().border_color(t.chrome).bg(connected ? t.ansi2 : t.dim);
      const head = h_flex().id(`machine-${m ?? "local"}`).h(26).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().text_size(11).text_color(t.dim)
        .when(collapsed, el => el.mt(4).w(RAIL_CELL).justify_center().rounded(6).tooltip(m ? `${m} · ${connected ? "connected" : (machine?.state ?? "asleep").replace(/_/g, " ")}` : "This computer"))
        .cursor_pointer().hover(s => s.bg(t.hover))
        .on_click((_e, cx) => {
          folded ? this.folded.delete(m) : this.folded.add(m);
          localStorage.setItem("machines.folded", JSON.stringify([...this.folded]));
          cx.notify();
        })
        .when(!collapsed, el => el.child(icon))
        .when(collapsed, el => el.child(div().relative().flex_none().child(icon).when(Boolean(m), el => el.child(badge))))
        .when(!collapsed, el => el.child(div().flex_1().truncate().child(m ?? "This computer"))
          .when(!connected && !rebuilt, el => el.child(div().flex_none().child((machine?.state ?? "asleep").replace(/_/g, " "))))
          .when(rebuilt, el => el.child(h_flex().flex_none().gap(3).items_center()
            .child(div().max_w(140).truncate().child(repair?.error || "rebuilt ·"))
            .child(div().id(`machine-connect-${m}`).text_color(repair?.error ? t.blocked : t.muted)
              .hover(s => s.text_color(t.foreground))
              .tooltip(repair?.error || "This machine was rebuilt or replaced. Click to connect to the new one.")
              .on_click((_e, cx) => { cx.stop_propagation(); this.reconnect(machine, cx); })
              .child(repair?.busy ? "Connecting…" : "Connect"))))
          .when(connected, el => el.child(div().id(`machine-add-${m ?? "local"}`).flex_none().px(4).rounded(4).hover(s => s.bg(t.hover).text_color(t.foreground))
            .tooltip(`New space on ${m ?? "this computer"}`)
            .on_click((_e, cx) => { cx.stop_propagation(); run("space.new", { machine: m ?? "" }); }).child("+")))
          .child(div().size(6).rounded(3).flex_none().bg(connected ? t.ansi2 : t.dim))
          .child(svg(ICON(`chevron-${folded ? "right" : "down"}`)).size(11).flex_none()));
      if (!collapsed && rebuilt) return [head];
      const cell = collapsed ? railCell : (el) => el;
      if (folded) return [cell(head)];
      const rows = [...host.projects.flatMap((p) => p.rows), ...host.loose];
      if (!rows.length) {
        const empty = h_flex().id(`machine-new-${m ?? "local"}`).h(28).flex_none().px(collapsed ? 0 : 8).gap(7).items_center().rounded(7)
          .text_size(12).text_color(t.dim).hover(s => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => run("space.new", { machine: m ?? "" }))
          .when(collapsed, el => el.w(RAIL_CELL).rounded(6).justify_center().tooltip(`New space on ${m ?? "this computer"}`)
            .child(h_flex().size(18).rounded(5).border_1().border_color(t.dim).items_center().justify_center()
              .child(svg(ICON("plus")).size(10))))
          .when(!collapsed, el => el.child(svg(ICON("plus")).size(12)).child("New space there"));
        return [cell(head), loading(m) ? loadingRow(m) : cell(empty)];
      }
      if (collapsed) return [cell(head), ...rows.map((r) => this.compact(r, t))];
      return [
        head,
        ...host.projects.flatMap((p) => this.project(p, m, t)),
        ...host.loose.flatMap((r) => this.space(r, t, 0, `loose:${m}`)),
      ];
    });
  }

  chevron(key, folded, t) {
    return div().id(`fold-${key}`).size(14).flex_none().flex().items_center().justify_center().rounded(3).text_color(t.dim)
      .hover(s => s.bg(t.hover).text_color(t.foreground))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); this.toggle(key, cx); })
      .child(svg(ICON(`chevron-${folded ? "right" : "down"}`)).size(10));
  }

  project(p, m, t) {
    const key = `p:${p.repo}`;
    const folded = this.treeFolded.has(key);
    const status = urgent(p.rows.map((r) => r.w.status));
    const id = `${m ?? "local"}-${p.name}`;
    const head = h_flex().id(`project-${id}`).h(28).flex_none().pl(4).pr(6).gap(6).items_center().rounded(7).mt(2)
      .cursor_pointer().hover(s => s.bg(t.hover))
      .tooltip("Right-click: open a worktree")
      .on_click((_e, cx) => this.toggle(key, cx))
      .on_mouse_down("right", () => openOverlay({ mod: "worktree", kind: "dialog", width: 560, height: 480, props: { space: p.rows[0].w.id, action: "open" } }))
      .child(this.chevron(key, folded, t))
      .child(h_flex().size(18).flex_none().rounded(5).bg(hue(p.name)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...p.name][0]?.toUpperCase() ?? "?"))
      .child(div().flex_1().min_w(0).truncate().font_semibold().text_color(t.foreground).child(p.name))
      .when(folded && (status === "blocked" || status === "done" || status === "working"), el => el.child(this.status(status, t, `project-${id}`)))
      .child(div().id(`project-open-${id}`).flex_none().px(4).rounded(4).text_color(t.dim).hover(s => s.bg(t.raised).text_color(t.foreground))
        .tooltip("New space on main")
        .on_click((_e, cx) => { cx.stop_propagation(); this.newSpace(p, m, cx); })
        .child("+"));
    return [head, ...(folded ? [] : p.rows.flatMap((r) => this.space(r, t, 1, p.repo)))];
  }

  pill(id, text, color, t, tip, onClick) {
    return div().id(id).flex_none().px(5).h(17).rounded(4).flex().items_center().text_size(10.5).font_semibold()
      .bg(color + "22").text_color(color).hover(s => s.bg(color + "40"))
      .when(Boolean(tip), el => el.tooltip(tip))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); onClick(); })
      .child(text);
  }

  // A release lands where the drop line shows, even off the rows (below the last
  // space): `over` keeps the last space hovered in the dragged one's group.
  drop(cx) {
    const from = this.pressed, over = this.over;
    this.pressed = this.over = null;
    if (from !== null && over !== null && from !== over) run("space.move", { id: from, index: spaces().findIndex((s) => s.id === over) + 1 });
    else if (from !== null && from === over) run("space.select", { id: from });
    cx.notify();
  }

  // depth 1: under a project; 0: straight under its machine (no repo).
  // A drag reorders spaces within `group` only.
  space({ w, g, branch, pr, ticket }, t, depth, group) {
    const key = `s:${w.id}`;
    const folded = this.treeFolded.has(key);
    const on = w.active;
    const name = this.label(w, g, branch, pr, ticket);
    const colors = shared("space.colors") ?? {};
    const color = colors[w.id] ?? "ansi6";
    const fill = color.startsWith("#") ? color : (MARK[color] ?? t[color]);
    const prColor = !pr ? null : pr.state === "MERGED" ? t.ansi5 : pr.state === "CLOSED" ? t.ansi1 : pr.isDraft ? t.muted : t.ansi2;
    const order = spaces().map((s) => s.id);
    const from = order.indexOf(this.pressed), here = order.indexOf(w.id);
    const head = h_flex().id(`space-${w.id}`).h(28).flex_none().pl(depth ? 22 : 4).pr(6).gap(6).items_center().rounded(7)
      .when(on, (el) => el.bg(t.selected))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .on_mouse_down("left", () => { this.pressed = w.id; this.pressedGroup = group; this.over = w.id; })
      .on_mouse_down("right", () => openOverlay({ mod: "menu", kind: "popup", width: 200, height: 260, props: { tab: "space", target: { id: w.id } } }))
      .child(this.chevron(key, folded, t))
      .when(depth === 0, (el) => el.child(h_flex().size(18).flex_none().rounded(5).bg(fill).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...w.name][0]?.toUpperCase() ?? "?")))
      .child(div().id(`space-title-${w.id}`).flex_1().min_w(0).truncate().text_color(on ? t.foreground : t.muted).tooltip(name).child(name))
      .when(folded && w.status && w.status !== "idle", (el) => el.child(this.status(w.status, t, `space-${w.id}`)))
      .when(Boolean(ticket), (el) => el.child(this.pill(`ticket-${w.id}`, ticket.id, t.accent, t,
        [ticket.status, ticket.title].filter(Boolean).join(" · "), () => ticket.url && openUrl(ticket.url))))
      .when(Boolean(pr), (el) => el.child(this.pill(`pr-${w.id}`, `#${pr.number}`, prColor, t,
        `${pr.isDraft ? "Draft · " : ""}${pr.state.toLowerCase()} · ${pr.title}`, () => openUrl(pr.url))));
    const ps = panes();
    // The space and its tabs move as one block, so the drop line goes above or below all of it.
    return [v_flex().id(`space-block-${w.id}`).relative().flex_none().gap(1)
      .when(this.pressed === w.id && this.over !== w.id, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === w.id && this.pressed !== w.id, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(from < here, (line) => line.bottom(-1))
          .when(from > here, (line) => line.top(-1))))
      .on_mouse_move((_e, cx) => {
        if (this.pressed === null) return;
        const over = this.pressedGroup === group ? w.id : null;
        if (this.over !== over) { this.over = over; cx.notify(); }
      })
      .on_mouse_up("left", (_e, cx) => this.drop(cx))
      .child(head)
      .when(!folded, (el) => el.children((w.tabs ?? []).map((c) => this.tab(c, w, ps, t, depth))))];
  }

  tab(c, w, ps, t, depth) {
    const program = ps.find(p => p.tab === c.id && p.program?.agent)?.program ?? ps.find(p => p.tab === c.id)?.program;
    const name = c.named ? c.name : program?.name ?? `Tab ${c.name}`;
    const on = w.active && c.active;
    return h_flex().id(`tab-${c.id}`).h(24).flex_none().pl(depth ? 50 : 32).pr(6).gap(7).items_center().rounded(6).text_size(12.5)
      .when(on, (el) => el.bg(t.raised))
      .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
      .when(c.settled, (el) => el.opacity(0.6))
      .on_click(() => {
        if (!w.active) run("space.select", { id: w.id });
        run("tab.select", { id: c.id });
      })
      .on_mouse_down("right", (_e, cx) => { cx.stop_propagation(); openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: { id: c.id, space: w.id } } }); })
      .child(program?.icon
        ? (program.tint ? svg(program.icon).size(13).flex_none().text_color(on ? t.foreground : t.muted) : image(program.icon).size(13).flex_none())
        : svg(ICON("terminal")).size(13).flex_none().text_color(t.dim))
      .child(div().flex_1().min_w(0).truncate().text_color(on ? t.foreground : t.muted).child(c.zoomed ? `${name} Z` : name))
      .when(Boolean(c.status), (el) => el.child(this.status(c.status, t, `tab-${c.id}`)));
  }

  // The status mark (spinner, dot or ring), its word in a tooltip. `id`: unique per row.
  status(status, t, id) {
    const word = { working: "running", blocked: "needs you", done: "done", idle: "idle" }[status];
    const mark = status === "working" ? svg(ICON("spinner")).size(11).flex_none().text_color(t.working).spin(900)
      : status === "idle" ? div().size(7).flex_none().rounded(4).border(1.5).border_color(t.idle ?? t.dim)
      : div().size(7).flex_none().rounded(4).bg(t[status] ?? t.dim);
    return h_flex().id(`status-${id}`).flex_none().w(14).h(14).items_center().justify_center().when(Boolean(word), (el) => el.tooltip(word)).child(mark);
  }

  compact({ w }, t) {
    return railCell(h_flex()
      .id(`space-${w.id}`)
      .relative()
      .w(RAIL_CELL)
      .h(26)
      .rounded(6)
      .justify_center()
      .items_center()
      .when(w.active, (el) => el.bg(t.selected))
      .when(!w.active, (el) => el.hover((s) => s.bg(t.hover)))
      .tooltip(w.name)
      .on_click(() => run("space.select", { id: w.id }))
      .child(div().text_color(w.active ? t.foreground : t.muted).child(String(w.index)))
      .child(div().absolute().right(5).text_color(tone(t, w.status)).child(glyph(w.status))));
  }

  // agent.next / agent.prev follow the tree: machine, project, space, tab.
  orderAgents(tree) {
    const pos = new Map();
    for (const host of tree.values()) for (const r of [...host.projects.flatMap((p) => p.rows), ...host.loose]) pos.set(r.w.id, pos.size);
    const list = agents().map((a, i) => ({ a, i }));
    list.sort((x, y) => (pos.get(x.a.space) ?? 1e9) - (pos.get(y.a.space) ?? 1e9) || x.a.tab_index - y.a.tab_index || x.i - y.i);
    setAgentOrder(list.map(({ a }) => a.address));
  }

  render() {
    const t = theme();
    const collapsed = narrow();
    const sp = spaces();
    const ids = new Set(sp.map(p => p.id));
    const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
    let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
    for (const p of sp) {
      if (kept[p.id] || p.name === "~") continue;
      const uses = c => Object.values(kept).filter(v => v === c).length;
      kept[p.id] = PALETTE.reduce((best, c) => uses(c) < uses(best) ? c : best);
      changed = true;
    }
    if (changed) setShared("space.colors", kept);
    const tree = this.tree();
    this.orderAgents(tree);
    return v_flex().size_full().min_h(0).bg(t.chrome).text_size(13)
      .child(h_flex().h(31).pl(16).pr(10).items_center().justify_between().text_size(11.5).text_color(t.dim)
        .when(collapsed, el => el.pl(0).pr(0).justify_center())
        .when(!collapsed, el => el.child("Projects"))
        .child(div().id("space-new").size(26).flex_none().flex().items_center().justify_center().rounded(6).hover(s => s.bg(t.hover).text_color(t.foreground))
          .tooltip("New space")
          .on_click(() => run("space.new")).child(svg(ICON("plus")).size(14))))
      .child(v_flex().flex_1().min_h(0).px(collapsed ? 0 : 8).pb(14).gap(1).overflow_y_scrollbar().mode("always")
        .on_mouse_up("left", (_e, cx) => this.drop(cx))
        .children(this.grouped(t, collapsed, tree)));
  }
}
