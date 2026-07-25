---
description: Build a client-facing Astro documentation site from source materials in the project directory
---

# Build a client documentation site

You are in a freshly-initialised Astro project (the minimal template) for a new client. The project directory contains source materials (Markdown, HTML notes, prose, sometimes early illustrations) for a client-facing documentation site — usually a roadmap, sometimes a multi-page docs handbook.

**Follow the phases below in order. Do not skip a phase.**

---

## Phase 1 — Ask what we're building

Use the `AskUserQuestion` tool with this exact question:

> **What are we building?**

Two options:

- **Roadmap** — a single-page timeline of phases / milestones. The landing page *is* the roadmap. (e.g. Ozeaon.)
- **Multi-page docs** — a landing index that links to sibling documentation pages, each illustrated. (e.g. Amagi handbook, CHIRPdb docs.)

Wait for the answer before proceeding.

---

## Phase 2 — Read the source materials and infer client identity

Read every source file the user placed in the project directory. Skip `node_modules`, `.git`, `src/`, `public/`, and lockfiles — read everything else.

Extract:

- **Client name / product name** — from titles, headings, and prose.
- **Brand colours** — any hex codes, palette references, or design-token blocks in source docs (SVG fills, CSS custom properties, style guides). If none are present, pick a neutral warm palette (off-white paper, dark ink, one accent).
- **Site title** — for `<title>` on the landing page (e.g. "OZEAON — Product Roadmap", "Amagi — Documentation").
- **Repo name for GH Pages** — the current directory name (`basename "$PWD"`). This becomes `base: '/<name>'`.
- **GitHub username** — try `gh api user --jq .login`. Fall back to asking.

Show the user what you inferred as a short bulleted summary and ask them to confirm or correct before you proceed. Do not proceed until confirmed.

---

## Phase 3 — Build the site

Work on top of the existing Astro scaffold (`src/pages/`, `src/layouts/`, `public/`). Overwrite the default `src/pages/index.astro`.

### Common to both output types

- `src/layouts/Layout.astro` — one shared layout. Takes a `title` prop. Emits `<html lang="en">`, `<head>` (charset, viewport, `<title>{title}</title>`, `<link rel="stylesheet" href={\`${base}styles.css\`} />`, favicon), and `<slot />` for the body. Use `const base = import.meta.env.BASE_URL;` — this is what makes assets resolve correctly under `/repo-name/`.
- `public/styles.css` — global stylesheet with CSS variables for the palette (light — and dark if the source docs suggest one, via `@media (prefers-color-scheme: dark)`), base body typography, and shared primitives only (`.brand`, `.brand-mark`, hero `em` accent). Layout-specific styles do NOT live here.
- Every page is **illustrated**. These sites lean visual — SVG flowcharts, timeline spines, hierarchy trees, badge-style stage numbers, dashed off-ramp lanes, colour-coded actor dots. Look at the source content, then design the illustration around it. Do not ship a text-only page unless the source really is nothing but prose.
- Per-page CSS lives inside the page's own `<style is:global>` block, not the shared stylesheet.
- Interior links between pages use `${base}<slug>` (from `import.meta.env.BASE_URL`) so they work under the GH Pages base path.

### If "Roadmap"

- Single page: `src/pages/index.astro`.
- Structure: hero (kicker / title / lede) → vertical timeline of phases with numbered nodes and per-phase cards (deliverables, dates, owners, RAG chips if present in the source). Model the visual on the current-state amagi client-journey timeline: `.journey::before` gradient spine, `.stage-num` circle nodes, `.stage-card` bodies, `.stage-list` bullet points, `.status-chip` badges.
- No sibling pages unless the source materials genuinely include distinct off-roadmap docs (e.g. a compliance or security appendix). If they do, add them as extra `src/pages/<slug>.astro` files and link them from the roadmap footer.

### If "Multi-page docs"

- `src/pages/index.astro` — landing page with a card grid linking to each doc. Each card: eyebrow (doc type), title, description, `→` CTA. Model on the amagi index card grid.
- One `src/pages/<slug>.astro` per source doc; filename = slug used in links.
- Each doc page: hero + heavily illustrated body (flow diagrams, hierarchy trees, staged narratives — whatever the source calls for).

---

## Phase 4 — GH Pages deployment

Set up deployment per <https://docs.astro.build/en/guides/deploy/github/>.

### `astro.config.mjs`

```javascript
// @ts-check
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://<gh-username>.github.io',
  base: '/<repo-name>',
});
```

Substitute the GH username and repo name from Phase 2.

### `.github/workflows/deploy.yml`

Write verbatim:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout your repository using git
        uses: actions/checkout@v7
      - name: Install, build, and upload your site
        uses: withastro/action@v6

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

The action auto-detects the package manager from the lockfile — no manual pnpm/npm config needed.

### Manual steps to tell the user at the end

Print (do NOT do these yourself):

1. Create a GitHub repo named `<repo-name>` under `<gh-username>`.
2. Push this branch to `main`.
3. In repo **Settings → Pages**, set source to **GitHub Actions**.
4. Site will publish at `https://<gh-username>.github.io/<repo-name>/`.

---

## Phase 5 — Smoke test

Run `pnpm dev` in the background (Astro dev server on port 4321). Fetch the landing page with `curl -s http://localhost:4321/<repo-name>/ | head -40` and confirm it responds with the expected `<title>`. Report the local URL to the user.

---

## Notes

- Do not add a password/auth gate unless the user explicitly asks. Client roadmaps and docs are usually public / shared via link.
- Do not add framework integrations (React, Vue, MDX) unless the source docs demand something Astro's built-in components can't do — these are static, illustrated pages.
- Do not fabricate content. If the source docs are thin, ship a smaller site rather than padding.
- Keep CSS tokens per-project — don't reuse a previous client's palette wholesale. Read what's in *this* directory.
