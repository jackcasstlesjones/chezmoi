---
description: Thorough, structured code review of the current branch against develop in the Ozeaon V2 codebase, with Monday ticket context resolved from the branch/PR
argument-hint: "[file-or-feature] (default: whole branch diff)"
allowed-tools: Bash(git*), Bash(gh*), Bash(pnpm*), Bash(find*), Bash(cat*), Read, Grep, Glob, mcp__claude_ai_monday_com__search, mcp__claude_ai_monday_com__get_board_items_page, mcp__claude_ai_monday_com__get_board_info, mcp__claude_ai_monday_com__read_docs, mcp__claude_ai_monday_com__get_updates, mcp__claude_ai_monday_com__all_monday_api, mcp__claude_ai_Google_Drive__search_files, mcp__claude_ai_Google_Drive__read_file_content, mcp__claude_ai_Google_Drive__get_file_metadata
---

# Ozeaon V2 — Code Review

IMPORTANT! Git diff with `develop`, NOT `main`. Review ONLY changes made in this branch. Watch for vibe-coding signs: unnecessary fallbacks, overcomplicated data processing, non-SOLID code.

Structured code review for the Ozeaon V2 platform: Next.js 16 App Router, React 19, Supabase,
Zod 4, React Hook Form, Cloudflare R2/Workers, TypeScript strict mode.

If `$1` is provided, scope the review to that file or feature area.

---

## Stack at a glance (memorise before reviewing)

| Concern     | Technology                                          | Key constraint                                                  |
| ----------- | --------------------------------------------------- | --------------------------------------------------------------- |
| Framework   | Next.js App Router (see `package.json` for version) | `cookies()` / `headers()` are async — must be awaited           |
| Runtime     | React 19 Server Components                          | `use client` at the leaves only                                 |
| Database    | Supabase + RLS                                      | Always use correct client for context (see §5)                  |
| Validation  | Zod 4                                               | Schemas live in `src/zod/`; use `TablesInsert<>` for mutations  |
| Forms       | React Hook Form 7                                   | RHF wrappers in `ui/forms/hook-form/`; domain hooks in `hooks/` |
| Storage     | Cloudflare R2 (Workers binding)                     | Use `StorageAdapter`, not S3-compatible API                     |
| Styling     | Tailwind CSS 4 + design system                      | Never raw `text-sm`, `text-gray-*` — use design tokens          |
| Package mgr | pnpm                                                | Never npm or yarn                                               |
| Deployment  | OpenNext + Wrangler (CF Workers)                    | No Node-only APIs; avoid `window`/`document` at module level    |

---

## 0. Identify the ticket (do this FIRST)

Before gathering PR context, resolve the Monday ticket this branch is scoped to and read its full description.

1. **Find the ticket id** from the branch name or PR description. The prefix carries the type:
   - `tozn-<number>` → **feature** ticket
   - `bozn-<number>` → **bug** ticket
   - Branch shape is usually `tozn-<TICKET>-pr-description` (e.g. `tozn-332-add-image-cache` → ticket `tozn-332`). The full ticket id **includes the prefix**.

   ```bash
   # Get current branch — the id is usually here
   git branch --show-current

   # Fall back to the PR title/body if the branch has no id
   gh pr view --json title,body 2>/dev/null
   ```

   If neither the branch nor the PR carries a `tozn-` / `bozn-` id, note the absence and skip to §1.

2. **Look the ticket up in Monday** with the Monday MCP. Search the full id (e.g. `tozn-332`):
   - `mcp__claude_ai_monday_com__search` — locate the item by its id.
   - `mcp__claude_ai_monday_com__get_board_items_page` / `mcp__claude_ai_monday_com__get_board_info` — read the item's status, column values, and acceptance criteria.
   - `mcp__claude_ai_monday_com__get_updates` — read discussion threads and clarifications.
   - `mcp__claude_ai_monday_com__read_docs` — if the description references a Monday doc.

3. **Google Docs fallback.** Sometimes the ticket description is simply a Google Docs link. When it is, open that doc via the Google Drive connector — it holds the full details of what this PR was scoped to solve:
   - `mcp__claude_ai_Google_Drive__search_files` (by the doc title) or read directly if you have the file id.
   - `mcp__claude_ai_Google_Drive__read_file_content` — pull the doc body.

Use the ticket + linked doc to establish:

- **Intent** — what problem this PR is meant to solve.
- **Acceptance criteria** — what "done" means; cross-check the diff against it later.
- **Scope creep** — anything in the diff not covered by the ticket/doc is a flag, but this may be justified in the PR description.

---

## 1. PR Context

After resolving the ticket, gather context from the active PR on this branch:

```bash
# Get current branch
git branch --show-current

# View PR details (description, status, reviewers)
gh pr view --json title,body,state,reviewDecision,labels,assignees,milestone

# Read PR comments and review threads
gh pr view --comments

# Check linked issues from the PR body (gh parses closing keywords)
gh pr view --json closingIssuesReferences --jq '.closingIssuesReferences[]'

# Fetch each linked issue's body and comments for acceptance criteria
gh issue view <issue-number> --json title,body,labels,comments
```

Use this context to:

- Understand **intent** — what problem the PR solves
- Extract **acceptance criteria** from the Monday ticket and any linked issues
- Note any **reviewer concerns** already raised
- Spot **scope creep** — changes not covered by the ticket/issue/description

If no PR exists for the branch, skip to §2 and note the absence.

---

## 2. Triage

1. **Scope**: single file → §4 directly. Multiple files / feature → §3 orientation first.
2. **File type**: classify before reviewing:
   - `app/**/page.tsx` — Server Component page
   - `app/**/route.ts` — API route
   - `app/**/layout.tsx` — layout
   - `components/` — UI component (server or client?)
   - `hooks/` — client hook
   - `lib/supabase/` — data access
   - `zod/` — validation schema
   - `utils/` — pure utility
   - `src/middleware.ts` — edge middleware

---

## 3. Project / Feature Orientation

When reviewing multiple files or a new feature area:

```bash
# Identify recently changed files
git log --name-only --pretty="" -20 | sort | uniq -c | sort -rn | head -20

# Find all files in a feature area
find src -path "*<feature>*" -not -path "*/node_modules/*" | sort

# Check for TypeScript errors
pnpm tsc --noEmit 2>&1 | head -40

# Check for lint errors
pnpm lint 2>&1 | head -40
```

Config files to check on a full-project review:

| File                | What to verify                                                |
| ------------------- | ------------------------------------------------------------- |
| `next.config.ts`    | Image domains, CF Workers compat, experimental flags          |
| `src/middleware.ts` | Auth guard matchers, redirect chains, edge API usage          |
| `src/config/env.ts` | All required env vars validated; no secrets exposed to client |
| `wrangler.jsonc`    | R2 bucket binding named `R2_BUCKET`, correct routes           |

---

## 4. File-Level Review

Read the file **twice** before commenting — once for intent, once for issues. Never skim.

```bash
cat src/<path/to/file>
```

Classify every finding by severity:

- 🔴 **Critical** — bug, security hole, broken auth, data loss, or build failure
- 🟡 **Warning** — anti-pattern, performance problem, RLS bypass risk, likely future bug
- 🟢 **Suggestion** — idiomatic improvement, design system compliance, readability

---

## 5. Review Checklist

### Supabase Client Usage

This is the most common source of bugs in this codebase. Check every `createClient` call.

- [ ] Is the **correct client** used for the context? See CLAUDE.md § "Supabase Client Patterns" for the
      Server/Client/Admin/Public selection table — don't re-derive it here, just check the call against it.
- [ ] Is `await createClient()` used in server contexts? (missing `await` is a silent bug)
- [ ] Is the browser client instantiated at module level / in a closure that persists across users? (must be fresh per component render)
- [ ] Are all Supabase responses destructured and the `error` field checked before using `data`?
- [ ] Are mutations using `TablesInsert<"table_name">` / `TablesUpdate<"table_name">` — not hand-rolled shapes?
- [ ] Are reusable queries extracted to `src/lib/supabase/queries/` rather than inlined in components?
- [ ] Is `.eq("user_id", user.id)` present on all user-scoped mutations (ownership check, belt-and-suspenders over RLS)?

### Authentication & Security

- [ ] Do API routes and Server Actions authenticate via `withAuthUser()` (route handlers), `getAuthUser()` (mid-function check), or `getAuthUserOrRedirect()` (pages) from `@/lib/supabase/queries/auth`, returning 401 if no user? Raw `supabase.auth.getUser()` / `.getSession()` calls are banned by `eslint.rules.auth.mjs` — that rule also bans `.getSession()` outright (unvalidated local JWT) and points server code at `getClaims()` / `getAuthUser()`, client code at `useAuth()` / `useActiveAccount()`. Flag anything that slipped past lint.
- [ ] Are secrets (`SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, R2 binding) accessed server-side only — never passed to Client Components or prefixed `NEXT_PUBLIC_`?
- [ ] Is `dangerouslySetInnerHTML` used? If so, is the content sanitised?
- [ ] Are file uploads validated for type and size using `validateFileType` / `validateFileSize` from `@/utils` before calling `StorageAdapter`?
- [ ] Does middleware cover all private routes? Check `matcher` config in `src/middleware.ts`.
- [ ] Are hardcoded credentials, tokens, or API keys present anywhere?

### Server vs Client Components (React 19 App Router)

- [ ] Is `use client` placed as close to the interactivity as possible — not hoisted to parent wrappers?
- [ ] Are browser APIs (`window`, `document`, `localStorage`) absent from Server Components and module-level code?
- [ ] Are `cookies()` and `headers()` awaited? (Next.js 16 breaking change — forgetting `await` is a common silent bug here)
- [ ] Are `loading.tsx` and `error.tsx` files present alongside async page segments?
- [ ] Is `Suspense` used to stream slow data rather than blocking the whole page?
- [ ] Is data fetched in parallel where possible? (`Promise.all([...])` not sequential `await`s)

### Zod Schemas & Validation

- [ ] Do schema files live in `src/zod/`? Never define schemas inline in components.
- [ ] Are Zod 4 APIs used — not deprecated Zod 3 methods?
- [ ] Is `src/zod/validators.ts` used for shared field validators (email, slug, URL, etc.) rather than re-defining rules?
- [ ] Are Server Action inputs validated against a Zod schema before touching the DB?
- [ ] Do Zod field names match the DB column names exactly? (e.g. `author_name` vs `display_name` — a known pain point)
- [ ] Are API response shapes validated with Zod where the response comes from an external source?

### React Hook Form & Multi-Step Forms

- [ ] Are RHF-connected fields using the wrappers in `src/components/ui/forms/hook-form/` — not raw `<input>`?
- [ ] For project forms, is `useProjectForm` used? For organization forms, `useOrganizationForm`?
- [ ] For article forms: there is no `useArticleForm` hook. `ArticleForm.tsx` calls `useForm` +
      `zodResolver(articleDraftSchema | articlePublishSchema)` directly and delegates step validation to
      `use-article-validation.ts` — check new article form code follows that shape, not a parallel one.
- [ ] Are derived fields (auto-slug from title) computed in the form hook's own watch/reset flow — as
      `use-project-form.ts` does for section slugs — not in an ad-hoc `useEffect` in a component?
- [ ] Are form submissions guarded against double-submit? (`isSubmitting` from RHF or `LoadingButton`)

### R2 Storage

- [ ] Is `StorageAdapter` used for all file operations — not the raw `r2-binding.ts` or an S3 client?
- [ ] Are storage keys generated with `generateUniqueKey` — not manually constructed strings?
- [ ] Is `cacheControl: "public, max-age=31536000, immutable"` set on immutable assets?
- [ ] Are image URLs built with `getImageUrl` / `getImageUrlFromKey` (`@/utils/url/image`) — which resolve to `NEXT_PUBLIC_STORAGE_URL` or fall back to `/api/storage` (Cloudflare Cache API + ETag 304) — not hand-built R2 URLs?
- [ ] Is `StorageAdapter.deleteFile(key)` called when a file is replaced or removed?

### TypeScript & Type System

- [ ] Are `any` types present? Flag every one — strict mode means there's always a better option.
- [ ] Is the derivation hierarchy followed?
  1. `Tables<"table">` — full row, use directly
  2. `Pick<Tables<"table">, "id" | "name">` — partial projection
  3. `Tables<"table"> & { joined: JoinedType }` — join result
  4. `Omit<Tables<"table">, "fk_col"> & { fk_col: JoinedShape }` — FK override
  5. `TablesInsert<>` / `TablesUpdate<>` — mutations only
- [ ] Are domain types defined in `src/types/` — never inside component files?
- [ ] Are `unknown` catch clause values narrowed before use?
- [ ] Are non-null assertions (`!`) used where `?.` or a null check would be safer?
- [ ] After TypeScript changes: does `pnpm tsc --noEmit` pass cleanly?

### Component Structure & Design System

- [ ] Are **raw Tailwind size/color utilities** used? Flag all violations:
  - ❌ `text-sm`, `text-xs`, `text-base`, `text-lg`, `text-gray-500`, `text-black`
  - ✅ Design tokens: `font-body`, `font-body-sm`, `font-h3`, `text-primary`, `text-muted`, `text-secondary`, etc.

- [ ] Are primitives used correctly — not re-implemented inline?

  | Primitive        | Use for                                                  | Anti-pattern it replaces                      |
  | ---------------- | -------------------------------------------------------- | --------------------------------------------- |
  | `EmptyState`     | All empty list/section states                            | `<div className="text-center">`               |
  | `DateDisplay`    | All date rendering (`"relative"` / `"short"` / `"long"`) | Manual `new Date().toLocaleDateString()`      |
  | `GridLayout`     | Responsive card grids                                    | `<div className="grid gap-4 sm:grid-cols-2">` |
  | `LoadingButton`  | Buttons with async loading state                         | Manual spinner + disabled state               |
  | `ConfirmDialog`  | Confirmation prompts                                     | `window.confirm()`                            |
  | `useAsyncAction` | Imperative async actions (follow, connect, block)        | `useState + try/catch + toast`                |

- [ ] Are icons passed as component references to `iconLeft`/`iconRight` props — not as JSX children?

  ```tsx
  // ✅
  <Button iconLeft={ArrowLeft}>Back</Button>
  // ❌
  <Button><ArrowLeft /> Back</Button>
  ```

- [ ] Are imports using the correct barrel paths?

  ```tsx
  // ✅
  import { EmptyState, DateDisplay } from "@/components/ui";
  import { PostCard } from "@/components/posts/cards";
  import { useAuth } from "@/hooks";
  // ❌ Old/wrong locations
  import { PostCard } from "@/components/cards/PostCard";
  import { TextField } from "@/components/inputs";
  ```

- [ ] Are new shadcn components added via CLI — not manually written?

  ```bash
  pnpm dlx shadcn@latest add <component-name>
  ```

- [ ] Are components over ~200 lines? Flag for extraction.
- [ ] Is business logic in UI components instead of hooks or utils?

### API Routes

- [ ] Does every route follow: auth check → validate body → query → typed response?
- [ ] Are correct HTTP status codes returned? (201 create, 400 validation, 401 unauth, 404 not found, 500 error)
- [ ] Is `TablesInsert<>` used to type the insert shape — not `body as any`?
- [ ] Are errors caught and returned as `{ error: error.message }` — not leaking stack traces?
- [ ] Is `console.error` (not `console.log`) used for server-side errors?

### Error Handling

- [ ] Are all async operations in API routes wrapped in `try/catch`?
- [ ] Are errors surfaced to the user via toast using `@/utils/toast` — not swallowed silently?
- [ ] Is `supabase-error.ts` used to normalise Supabase error messages before display?
- [ ] Are `error.tsx` boundaries present for all async page segments?
- [ ] Are `notFound()` / `redirect()` from `next/navigation` used in Server Components — not manual responses?

### State Management

- [ ] Is a new global-state library being introduced? There is no store library in this project (no Zustand,
      no Redux) — global client state is React Context (`SessionProvider`, `RepostProvider`). Adding one is a
      🔴 dependency decision, not a local choice.
- [ ] Is server-fetched data being duplicated into `useState`? (anti-pattern — pass as props or fetch in RSC)
- [ ] Are Context providers wrapping unnecessarily large subtrees?

### Performance

- [ ] Are images using `next/image` with explicit `width`, `height`, and `alt`?
- [ ] Are fonts loaded via `next/font` — not `@import` in CSS?
- [ ] Are heavy libraries (e.g. BlockNote) dynamically imported with `next/dynamic`?
- [ ] Are large lists paginated — not fetched entirely?
- [ ] Are Supabase queries selecting only needed columns — not `select("*")` on large tables?

### Code Quality

- [ ] Are `console.log` / debug statements present that shouldn't reach production?
- [ ] Are dead imports or unused variables present? (`pnpm lint` will catch these)
- [ ] Are magic strings / numbers inlined where named constants from `src/config/constants/` exist?
- [ ] Are promises left unawaited?

---

## 6. Output Format

Always prioritise by severity, not by file order.

The review is emitted in **two parts, in this order**: the detailed findings, then a numbered
index that recaps them. Never emit the findings without the index, and never emit the index
alone — the index is a lookup table, not a substitute for the reasoning.

### 6.1 Finding IDs

Every finding gets a stable ID, assigned in the order it appears within its category:

| ID  | Category               | Meaning                                                                   |
| --- | ---------------------- | ------------------------------------------------------------------------- |
| `C` | 🔴 Critical            | Bug, security hole, broken auth, data loss, build failure                 |
| `W` | 🟡 Warning             | Anti-pattern, perf problem, RLS bypass risk, likely future bug            |
| `S` | 🟢 Suggestion          | Idiomatic improvement, design system compliance, readability              |
| `D` | 📋 Description / scope | PR-body claims that don't match the diff, scope creep, unreviewable diffs |

So: `C1, C2, …`, `W1, W2, …`, `S1, S2, …`, `D1, D2, …`.

IDs exist so the user can refer back to a finding in their next message — "comment C1 and W1",
"fix W3", "ignore the S items". Assign them even on a single-file review. Once assigned, IDs are
fixed for the rest of the conversation: if a later turn adds a finding, give it the next free
number in its category rather than renumbering.

Keep `D` separate from `S` on purpose. `D` items are about the pull request's **description and
scope**, not its code — a fix listed in the body but absent from the diff, a ticket the branch
name doesn't mention, a 600-line diff that is 596 lines of re-indentation. They get reported and
discussed, never "applied".

### 6.2 Detailed findings — emit first

````
## Code Review: [filename or feature name]

### Tickets
[ticket ids (e.g. tozn-332) + one-line scope from the Monday ticket / linked Google Doc, or
"no ticket found". If the branch name and the PR body disagree on which tickets are in scope,
say so here in one line — it is usually the first sign of a `D` finding.]

### Summary
One paragraph: overall quality, biggest concerns, what's done well. Lead with whether the diff
actually does what the PR body claims.

### 🔴 C1 — [Short title]
`src/path/to/file.tsx:N`

What the problem is, why it matters, concrete fix. Show the mechanism, not just the symptom —
name the thing that makes it break (a default action that isn't prevented, a policy that ORs
with another, a component that never re-renders).

```tsx
// Before
...
// After
...
```

### 🟡 W1 — [Short title]
`src/path/to/file.tsx:N`

...same shape...

### 🟢 Suggestions
Short items can collapse to one bullet each, still ID'd: **S1** — `hidden md:block` should be
`md:inline` → `src/path/File.tsx:N`

### 📋 Description / scope
**D1** — [claim in the PR body] vs [what the diff actually contains].

### ✅ What's working well
Callouts of good patterns to reinforce. Be specific — name the file and the pattern, not
"good code structure".
````

### 6.3 Findings index — emit last

Close every review with this. One line per finding, no re-explanation, with the `file:line` so
each line is clickable.

```
---

**Critical**
- **C1** — [compressed one-line claim] → `src/path/to/file.tsx:N`
- **C2** — … → `path:N`

**Warnings**
- **W1** — … → `path:N`

**Suggestions**
- **S1** — …

**Description / scope**
- **D1** — …
```

Then a single closing line: the two or three IDs you'd act on first, and what kind of action each
needs (fix now / needs a decision / discuss only). Do not restate the findings.

### 6.4 Confidence

State confidence honestly, per finding. There are two kinds of finding and they must not be
confused:

- **Verified** — you read the mechanism and confirmed it. ("`Button` spreads `type` onto the
  native `<button>` at `button.tsx:129`, and `handleRemove` never calls `preventDefault`.")
- **Inferred** — it looks wrong from the diff alone, but you did not check the thing that would
  disprove it.

Anything still inferred gets `(unverified: <what would settle it>)` appended to its index line.
Before a finding leaves this conversation — posted as a PR comment, filed, or acted on — either
verify it or say plainly that it is unverified. Guessing wrong in public on a colleague's PR
costs more than the finding is worth. If you notice mid-review that a finding is about to
collapse, say so and offer to check rather than shipping it.

Rules:

- Lead with the most severe issue, not the first file
- Every finding gets a concrete fix — not just a description
- Cross-check findings against the ticket's acceptance criteria; flag any unmet criteria as 🔴
  and any change outside scope as a `D` finding
- For large fixes, offer: _"Want me to apply this?"_
- Cap at ~10 items per category for full-feature reviews
- Reference CLAUDE.md section names when pointing to conventions

---

## 7. Ozeaon Anti-Patterns (Quick Reference)

Full before/after table: `references/anti-patterns.md` — load it only if a finding doesn't fit the §5 checklist.

---

## 8. After the Review

The user will normally reply with finding IDs from the §6.3 index — "fix C1", "comment C1 and W1",
"drop the S items". Resolve them against the index and act only on what they named; don't widen to
neighbouring findings.

1. **Offer to apply fixes** for `C` and `W` items: _"Want me to apply any of these?"_
2. **Before acting on an ID**, re-check its §6.4 confidence. If it is still marked unverified,
   verify it first — and if verification collapses the finding, say so instead of acting on it.
3. **Posting to the PR** (`gh pr comment`, `gh pr review`) is outward-facing and visible to the
   team. It is fine to do when asked, but the comment must carry only verified findings, and it
   should read as review prose — the claim, the mechanism, the fix — not a pasted index line.
4. **Offer a deeper dive** if a category had 3+ issues
5. **Check related files** if tight coupling is spotted
6. **Run type check** after any TypeScript changes: `pnpm tsc --noEmit`
7. **Run lint** after component changes: `pnpm lint`

Apply fixes one at a time, confirm each before moving to the next.
