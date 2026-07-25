---
description: Add or refresh a collapsible changelog on an existing roadmap page (Astro or plain HTML), sourced from git history filtered to roadmap-content changes only
---

# Add / refresh a roadmap changelog

Insert a collapsible **Changelog** section on the current project's roadmap page, or refresh an existing one. Works on either an Astro project or a plain HTML roadmap.

Follow the phases below in order.

---

## Phase 1 — Locate the roadmap page

Find the file that renders the roadmap:

- If `src/pages/roadmap.astro` or `src/pages/index.astro` exists, the site is Astro. Prefer `roadmap.astro` if both exist.
- Otherwise, look for `roadmap/index.html`, or `index.html` at the repo root.
- If several candidates exist, ask the user which one is *the* roadmap.

Note the format (Astro vs HTML) — it determines how you insert markup.

---

## Phase 2 — Build the changelog rows from git history

Populate the changelog from `git log` — but filter aggressively.

1. Walk history first-commit → HEAD:
   ```bash
   git log --format='%h %ai %an %s' --reverse
   ```
2. For each commit, inspect the diff (`git show --stat <sha>` then `git show <sha>` on interesting ones) and decide whether it changed **roadmap content** or just **rendering**.
3. **Include** commits that:
   - Add, remove, rename, or reorder roadmap items / phases / steps / packages.
   - Change scope, deliverables, day-budgets, owners, dates, or dependencies.
   - Split or merge items. Renumber steps. Change a step's "kind" (e.g. Built → AI).
   - Add or move milestones.
   - First-publish commits ("roadmap first published: N steps across M packages").
4. **Exclude** commits that only change:
   - CSS, colours, borders, spacing, delimiters, font sizes.
   - Rendering / layout / template refactors, componentisation, deduping.
   - Adding or removing hero blocks, page chrome, headers, footers.
   - Fixing typos, punctuation, or broken links.
   - Build / deploy / dependency / lockfile / workflow changes.
   - The changelog section itself.
5. Write each surviving commit as one row: **date** (from `%ai`, formatted as "25 Jul 2026"), **description** (a plain-English sentence about the roadmap change — write it fresh from the diff, do NOT copy the commit message), **author** (from `%an`).
6. If a commit's diff is ambiguous (touches both content and styling), only the content change goes in the row.
7. If git history is empty or has only the initial scaffold commit, seed the changelog with a single "Roadmap first published" row dated today.

Mark rows with `class="is-milestone"` (and a `<span class="changelog__milestone-tag">Milestone</span>` prefix in the first cell) for structural events: first publish, phase budgets defined, package count changed, delivery-model pivots.

Rows are ordered **newest first** in the final table. The "Last updated" caption shows the newest included row's date.

---

## Phase 3 — Insert (or replace) the changelog

The changelog sits between the page hero and the roadmap timeline.

**If a `<section class="changelog">` already exists on the page**, replace it in place — keep the surrounding markup untouched. Do not duplicate.

**Otherwise, insert it immediately after the closing tag of the hero block** (usually `</header>` or `</section>` for the hero). If you can't confidently locate the hero, ask the user where to put it.

### CSS

Add the following to the page's stylesheet (`<style>` block for HTML, `<style is:global>` block for Astro). If any of these selectors already exist, leave them; do not duplicate.

```css
.changelog {
  background: var(--bg-card, var(--card, #fff));
  border-bottom: 1px solid var(--border, var(--line, #E7DFD1));
}
.changelog__inner {
  max-width: 1000px;
  margin: 0 auto;
  padding: 0 24px;
}
.changelog__toggle {
  appearance: none;
  background: none;
  border: 0;
  width: 100%;
  padding: 14px 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  cursor: pointer;
  color: var(--text, var(--ink));
  font: inherit;
}
.changelog__toggle:focus-visible {
  outline: 2px solid var(--accent, var(--amber, #C87A2F));
  outline-offset: 2px;
  border-radius: 4px;
}
.changelog__title {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--accent, var(--amber, #C87A2F));
}
.changelog__title::after {
  content: "";
  display: inline-block;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--text-soft, var(--ink-muted, #6B7688));
}
.changelog__count {
  color: var(--text-soft, var(--ink-muted, #6B7688));
  font-weight: 600;
  font-size: 13px;
  letter-spacing: 0;
  text-transform: none;
}
.changelog__chevron {
  color: var(--text-soft, var(--ink-muted, #6B7688));
  font-size: 14px;
  transition: transform 0.2s ease;
}
.changelog__toggle[aria-expanded="true"] .changelog__chevron {
  transform: rotate(180deg);
}
.changelog__body { padding-bottom: 20px; }
.changelog__body[hidden] { display: none; }
.changelog__table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}
.changelog__table th,
.changelog__table td {
  text-align: left;
  padding: 10px 12px;
  border-bottom: 1px solid var(--border-soft, var(--line, #E7DFD1));
  vertical-align: top;
}
.changelog__table th {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--text-soft, var(--ink-muted, #6B7688));
  font-weight: 700;
  background: var(--bg-soft, var(--paper, #FBF7F0));
}
.changelog__table td:first-child {
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
  color: var(--text-soft, var(--ink-muted, #6B7688));
  width: 120px;
}
.changelog__table td:last-child {
  white-space: nowrap;
  color: var(--text-soft, var(--ink-muted, #6B7688));
  width: 140px;
}
.changelog__table tr.is-milestone td {
  background: var(--accent-tint, var(--amber-soft, #F4E4D0));
  border-bottom-color: color-mix(in srgb, var(--accent, var(--amber, #C87A2F)) 35%, transparent);
  color: var(--text, var(--ink));
  font-weight: 500;
}
.changelog__table tr.is-milestone td:first-child {
  border-left: 3px solid var(--accent, var(--amber, #C87A2F));
  color: var(--accent-deep, var(--amber-ink, #7A3E0B));
  font-weight: 700;
}
.changelog__milestone-tag {
  display: inline-block;
  margin-right: 8px;
  padding: 2px 7px;
  background: var(--accent, var(--amber, #C87A2F));
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  border-radius: 4px;
  vertical-align: 1px;
}
@media (max-width: 640px) {
  .changelog__inner { padding: 0 18px; }
  .changelog__table th,
  .changelog__table td { padding: 8px 8px; font-size: 13px; }
  .changelog__table td:first-child { width: auto; }
  .changelog__table td:last-child { width: auto; white-space: normal; }
}
```

The palette variables use `var(--brand-name, var(--fallback, hex))` chains so they slot into whichever token names the existing page already uses.

### Markup

```html
<section class="changelog" aria-labelledby="changelogTitle">
  <div class="changelog__inner">
    <button
      type="button"
      class="changelog__toggle"
      aria-expanded="false"
      aria-controls="changelogBody"
      id="changelogToggle"
    >
      <span class="changelog__title" id="changelogTitle">
        Changelog
        <span class="changelog__count">Last updated <!-- newest row date --></span>
      </span>
      <span class="changelog__chevron" aria-hidden="true">▾</span>
    </button>
    <div class="changelog__body" id="changelogBody" hidden>
      <table class="changelog__table">
        <thead>
          <tr>
            <th scope="col">Date</th>
            <th scope="col">Description</th>
            <th scope="col">Author</th>
          </tr>
        </thead>
        <tbody>
          <!-- one <tr> per surviving commit, newest first -->
          <!-- milestone rows use <tr class="is-milestone"> with a milestone tag in the first cell -->
        </tbody>
      </table>
    </div>
  </div>
</section>
```

### Toggle script

**HTML page:** append this inside the `<section class="changelog">` (or at the end of `<body>`):

```html
<script>
  (function () {
    var btn = document.getElementById("changelogToggle");
    var body = document.getElementById("changelogBody");
    if (!btn || !body) return;
    btn.addEventListener("click", function () {
      var open = btn.getAttribute("aria-expanded") === "true";
      btn.setAttribute("aria-expanded", open ? "false" : "true");
      if (open) body.setAttribute("hidden", ""); else body.removeAttribute("hidden");
    });
  })();
</script>
```

**Astro page:** put the same script inside a `<script is:inline>` block so Astro doesn't bundle it as a module.

---

## Phase 4 — Verify

- If Astro, run `pnpm dev` in the background and `curl -s http://localhost:4321<base>/` (or the roadmap slug) to confirm the page still renders and the changelog markup is present.
- If plain HTML, open the file and confirm the section is between the hero and the timeline, and the toggle script is present exactly once.
- Report the count of included / excluded commits to the user, plus the newest and oldest changelog dates.
