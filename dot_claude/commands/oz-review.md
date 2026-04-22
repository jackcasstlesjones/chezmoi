---
name: nextjs-code-review
description: Perform thorough, structured code reviews on Next.js files and features in the Ozeaon V2 codebase. Compare the diff with the 'develop' branch, making sure to only review changes that have been made in this branch.
compatibility:
  tools:
    - bash
    - view
    - str_replace
---

# Ozeaon V2 — Code Review Skill

IMPORTANT! Git diff with 'develop' not 'main'. Check for signs of vibe coding including unnecessary fallbacks, overcomplicated data processing, non-SOLID code.

Structured code review for the Ozeaon V2 platform: Next.js 16 App Router, React 19, Supabase,
Zod 4, React Hook Form, Cloudflare R2/Workers, TypeScript strict mode.

---

## Stack at a glance (memorise before reviewing)

| Concern     | Technology                       | Key constraint                                                  |
| ----------- | -------------------------------- | --------------------------------------------------------------- |
| Framework   | Next.js 16.1.7 App Router        | `cookies()` / `headers()` are async — must be awaited           |
| Runtime     | React 19 Server Components       | `use client` at the leaves only                                 |
| Database    | Supabase + RLS                   | Always use correct client for context (see §4)                  |
| Validation  | Zod 4                            | Schemas live in `src/zod/`; use `TablesInsert<>` for mutations  |
| Forms       | React Hook Form 7                | RHF wrappers in `ui/forms/hook-form/`; domain hooks in `hooks/` |
| Storage     | Cloudflare R2 (Workers binding)  | Use `StorageAdapter`, not S3-compatible API                     |
| Styling     | Tailwind CSS 4 + design system   | Never raw `text-sm`, `text-gray-*` — use design tokens          |
| Package mgr | pnpm                             | Never npm or yarn                                               |
| Deployment  | OpenNext + Wrangler (CF Workers) | No Node-only APIs; avoid `window`/`document` at module level    |

---

## 1. Triage

1. **Scope**: single file → §3 directly. Multiple files / feature → §2 orientation first.
2. **File type**: classify before reviewing:
   - `app/**/page.tsx` — Server Component page
   - `app/**/route.ts` — API route
   - `app/**/layout.tsx` — layout
   - `components/` — UI component (server or client?)
   - `hooks/` — client hook
   - `lib/supabase/` — data access
   - `zod/` — validation schema
   - `utils/` — pure utility
   - `stores/` — Zustand store
   - `middleware.ts` — edge middleware

---

## 2. Project / Feature Orientation

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
| `middleware.ts`     | Auth guard matchers, redirect chains, edge API usage          |
| `src/config/env.ts` | All required env vars validated; no secrets exposed to client |
| `wrangler.jsonc`    | R2 bucket binding named `R2_BUCKET`, correct routes           |

---

## 3. File-Level Review

Read the file **twice** before commenting — once for intent, once for issues. Never skim.

```bash
cat src/<path/to/file>
```

Classify every finding by severity:

- 🔴 **Critical** — bug, security hole, broken auth, data loss, or build failure
- 🟡 **Warning** — anti-pattern, performance problem, RLS bypass risk, likely future bug
- 🟢 **Suggestion** — idiomatic improvement, design system compliance, readability

---

## 4. Review Checklist

### Supabase Client Usage

This is the most common source of bugs in this codebase. Check every `createClient` call.

- [ ] Is the **correct client** used for the context?

  | Context                                    | Correct import                                                    |
  | ------------------------------------------ | ----------------------------------------------------------------- |
  | Server Component, API route, Server Action | `@/lib/supabase/server` (async, awaited)                          |
  | Client Component                           | `@/lib/supabase/client` (fresh per render, never cached globally) |
  | Admin op bypassing RLS                     | `@/lib/supabase/admin` (only in API routes, justified)            |
  | Unauthenticated public query               | `@/lib/supabase/public`                                           |

- [ ] Is `await createClient()` used in server contexts? (missing `await` is a silent bug)
- [ ] Is the browser client instantiated at module level / in a closure that persists across users? (must be fresh per component render)
- [ ] Are all Supabase responses destructured and the `error` field checked before using `data`?
- [ ] Are mutations using `TablesInsert<"table_name">` / `TablesUpdate<"table_name">` — not hand-rolled shapes?
- [ ] Are reusable queries extracted to `src/lib/supabase/queries/` rather than inlined in components?
- [ ] Is `.eq("user_id", user.id)` present on all user-scoped mutations (ownership check, belt-and-suspenders over RLS)?

### Authentication & Security

- [ ] Are API routes and Server Actions calling `supabase.auth.getUser()` and returning 401 if no user?
- [ ] Are secrets (`SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, R2 binding) accessed server-side only — never passed to Client Components or prefixed `NEXT_PUBLIC_`?
- [ ] Is `dangerouslySetInnerHTML` used? If so, is the content sanitised?
- [ ] Are file uploads validated for type and size using `validateFileType` / `validateFileSize` from `@/utils` before calling `StorageAdapter`?
- [ ] Does middleware cover all private routes? Check `matcher` config in `middleware.ts`.
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
- [ ] For article forms, is `useArticleForm` used (not a hand-rolled form state)?
- [ ] For project forms, is `useProjectForm` used?
- [ ] Is `use-field-sync.ts` used for derived fields like auto-slug from title — not custom `useEffect` watchers?
- [ ] Are form submissions guarded against double-submit? (`isSubmitting` from RHF or `LoadingButton`)

### R2 Storage

- [ ] Is `StorageAdapter` used for all file operations — not the raw `r2-binding.ts` or an S3 client?
- [ ] Are storage keys generated with `generateUniqueKey` — not manually constructed strings?
- [ ] Is `cacheControl: "public, max-age=31536000, immutable"` set on immutable assets?
- [ ] Are image URLs fetched through `/api/images` (with Cloudflare Cache API + ETag support) — not direct R2 URLs?
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

- [ ] Is Zustand used only for genuinely global client state (e.g. bookmarks store)?
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

## 5. Output Format

Always prioritise by severity, not by file order.

````
## Code Review: [filename or feature name]

### Summary
One paragraph: overall quality, biggest concerns, what's done well.

### 🔴 Critical Issues
1. **[Short title]** (`src/path/to/file.tsx`, line N)
   What the problem is, why it matters, concrete fix.
   ```tsx
   // Before
   ...
   // After
   ...
````

### 🟡 Warnings

...same format...

### 🟢 Suggestions

...same format...

### ✅ What's working well

Callouts of good patterns to reinforce.

```

Rules:
- Lead with the most severe issue, not the first file
- Every finding gets a concrete fix — not just a description
- For large fixes, offer: *"Want me to apply this?"*
- Cap at ~10 items per category for full-feature reviews
- Reference CLAUDE.md section names when pointing to conventions

---

## 6. Ozeaon Anti-Patterns (Quick Reference)

| Anti-pattern | Correct approach |
|---|---|
| `createClient()` without `await` in Server Component | `const supabase = await createClient()` |
| Browser Supabase client cached at module level | Fresh instantiation per component render |
| `select("*")` on large tables | Select only needed columns |
| Missing `.eq("user_id", user.id)` on mutations | Always scope writes to the authenticated user |
| Raw `text-sm` / `text-gray-500` | `font-body-sm` / `text-muted` (design tokens) |
| `<div className="grid gap-4 sm:grid-cols-2">` | `<GridLayout>` |
| Empty state as raw `<div className="text-center">` | `<EmptyState>` |
| `window.confirm()` | `<ConfirmDialog>` |
| Icons as JSX children of `<Button>` | `iconLeft={Icon}` prop |
| Hand-rolled insert type shape | `TablesInsert<"table_name">` |
| Domain type defined in a component file | Define in `src/types/` |
| Zod schema defined inline in a component | Define in `src/zod/<domain>/` |
| Sequential `await fetch1; await fetch2` in RSC | `Promise.all([fetch1, fetch2])` |
| `router.push` in a Server Component | `redirect()` from `next/navigation` |
| `useState + try/catch + toast` for async actions | `useAsyncAction` hook |
| `useEffect` to derive slug from title | `use-field-sync.ts` |
| `npm install` or `yarn add` | `pnpm add` |
| Manually writing a shadcn component | `pnpm dlx shadcn@latest add <n>` |

---

## 7. After the Review

1. **Offer to apply fixes** for 🔴 and 🟡 items: *"Want me to apply any of these?"*
2. **Offer a deeper dive** if a category had 3+ issues
3. **Check related files** if tight coupling is spotted
4. **Run type check** after any TypeScript changes: `pnpm tsc --noEmit`
5. **Run lint** after component changes: `pnpm lint`

Apply fixes one at a time with `str_replace`, confirm each before moving to the next.
```
