Take a JSON data file and produce a single self-contained `index.html` — interactive, mobile-friendly, no external runtime dependencies (Google Fonts is fine, nothing else). Output should be ready to drop onto GH Pages or open from disk.

The pattern: a sortable/filterable table on desktop that collapses to a card list on mobile. Vanilla JS, no build step, no frameworks.

## Step 1: Locate and inspect the data

If the user passed a path as an argument, use it. Otherwise look for `data.json` or `source.json` in the current directory. If neither exists, ask the user for the path.

Read the data and figure out:

- **Primary field** — the name/title column. Usually the first string field, or one obviously named `name`, `title`, etc.
- **Categorical fields** — short string values that repeat across rows (status, type, owner, region). Good candidates for badges, chips, or dropdown filters.
- **Numeric/temporal fields** — sortable. If a field is text like "~1.5 hrs" or "30 min" or "$25/night", write a parser; don't assume lexical sort works.
- **Long-text fields** — notes, descriptions, summaries. Get more horizontal space; searchable but not filterable.
- **The actual cardinality** — a categorical field with 2–6 distinct values wants chips; 7+ wants a dropdown. A field where every row is unique is not categorical.

Report what you found in one sentence ("I see 38 rows with fields: name, drive-time, permits, fee, terrain, notes — drive-time looks parseable into minutes, permits and fee look like chip filters") before asking the user anything.

## Step 2: Ask the user (one batched question set)

Use AskUserQuestion. Cover at minimum:

- **Theme** — light / dark / let-me-pick-accent. Use the `preview` option to show concrete colour samples.
- **Page title** — default to something inferred from the filename or data.
- **Filter strategy for ambiguous fields** — if it's unclear whether a field should be a chip filter, dropdown, or badge-only, ask. Don't guess on more than one field.

Do NOT ask about things you can decide confidently from the data (which field is the title, which is long-text, what to sort by default). Make the call and move on.

## Step 3: Generate the page

Output a single `index.html` in the same directory as the data file.

### File structure

```
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>...</title>
  <style>
    @import url("https://fonts.googleapis.com/css2?family=...&display=swap");
    :root { /* theme variables — colours, fonts */ }
    /* base, controls, table (desktop), cards (mobile) */
    @media (max-width: 720px) { /* table → cards */ }
  </style>
</head>
<body>
  <header>title, search input, filter chips/dropdowns</header>
  <div class="stats">Showing N of M</div>
  <div class="table-wrap"><table>...</table></div>
  <div class="empty">No matching rows.</div>
  <script type="application/json" id="data">...</script>
  <script>/* hydrate, filter, sort, render */</script>
</body>
</html>
```

Theme via CSS custom properties on `:root` — one place to tweak colours later. Data inlined either as a JS const or as `<script type="application/json">` (the latter is cleaner for larger datasets and keeps the data block uncluttered by escaping concerns).

### Required features

- **Search box** — filters across all visible text fields, case-insensitive.
- **Sortable columns** — click headers; show ▲/▼ indicator on the active column; toggle direction on second click.
- **Filters** — chips OR dropdowns depending on cardinality. Active filter has visible state (border + tinted background).
- **Stats line** — "Showing N of M". Updates live.
- **Empty state** — "No matching rows. Try clearing filters."
- **Touch targets** — inputs/selects ≥44px tall on mobile, `font-size: 16px` to prevent iOS zoom-on-focus.

### The mobile pattern (this is the key part)

At ≤720px, the desktop table becomes a stacked card list. Two viable approaches; pick based on the data:

**Approach A — transform `<td>` cells into grid rows.** Best when there are many short fields. Each `<td>` gets a `data-label` attribute (set during render), and CSS turns each row into a card and each cell into a labeled grid row:

```css
@media (max-width: 720px) {
  table, thead, tbody, tr, td { display: block; width: 100%; }
  thead { display: none; }
  tbody tr {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 14px;
    margin-bottom: 10px;
  }
  td {
    display: grid;
    grid-template-columns: 100px 1fr;
    gap: 10px;
    padding: 0;
  }
  td + td { margin-top: 8px; padding-top: 8px; border-top: 1px solid var(--border); }
  td::before {
    content: attr(data-label);
    font-size: 0.7rem;
    text-transform: uppercase;
    color: var(--muted);
  }
  td.primary { grid-template-columns: 1fr; font-size: 1.05rem; font-weight: 600; }
  td.primary::before { display: none; }
}
```

The primary/title cell drops the label and spans full width — that's what makes the card feel like a card and not a labeled list.

**Approach B — build separate `.card` markup alongside the table.** Best when fields are fewer but each holds more content (one paragraph of notes per row, etc). The table is hidden at the mobile breakpoint and the card list is shown:

```css
.card-list { display: none; }
@media (max-width: 720px) {
  .table-wrap { display: none; }
  .card-list { display: block; }
}
```

Render both during hydration; keep a Map from row element → card element so filter/sort updates both in lockstep.

Pick A by default. Use B when there's a single dominant text field (long notes/description) that wants its own visual block under the title rather than a labeled grid row.

### Visual conventions

- **Badges/pills** for short categorical values. One subtle base style, then per-category accent colours via additional classes. Don't rainbow-ify — pick 3–5 semantic colours max (e.g. green for "good", amber for "watch", red for "bad", grey for "neutral").
- **Sticky header** on desktop (`thead { position: sticky; top: 0; }`) so columns stay visible.
- **Sort indicator** — `▲` / `▼` next to the active column header, dimmed inactive indicators on hover.
- **Highlight search matches** with `<mark>` — small touch, big payoff.
- **No hover effects on mobile** — `:hover` styles get stuck on touch devices. Either gate behind `@media (hover: hover)` or override inside the mobile breakpoint.
- **`font-variant-numeric: tabular-nums`** on any numeric column so values line up.

### HTML/JS hygiene

- Escape user-supplied / data-supplied text before injecting as HTML. A small `escapeHTML()` helper is enough.
- Parse-on-render is fine at this scale — no need for virtual DOM or memoisation under ~1000 rows.
- Sort/filter state lives in one plain object; one `render()` function reads it and rewrites `<tbody>`. Don't scatter DOM updates across handlers.

### Things to avoid

- Don't add features the data doesn't justify. ≤50 rows means no pagination.
- Don't add an "export CSV" button unless asked.
- Don't use a charting library. If a chart is genuinely needed, ask first.
- Don't add a dark-mode toggle unless asked — the user picked one theme in Step 2.
- Don't ship commented-out code or placeholder TODOs.

## Step 4: Verify

After writing, briefly check:

- The file loads with no console errors.
- Filters and search both work.
- Mobile layout works (DevTools responsive mode is fine — don't ask the user to test on a phone).

Fix anything off before reporting done.

## Output

End with one or two sentences: where the file is, and any decisions worth flagging ("I treated `region` as a chip filter since there were only 4 distinct values"). Don't list everything you did — the diff is the diff.
