---
name: ludwig-vercel
description: Build an app continuously on a self-contained Next.js + Vercel + Neon stack and get it live on a production URL as early as possible. Follows /ludwig, adding the concrete stack, deploy wiring and platform tools.
argument-hint: "[idea for a new project | what to work on next | blank to continue the plan]"
---

# ludwig-vercel

Follow `/ludwig` (read `~/.claude/commands/ludwig.md` and apply all of it), with the concrete stack and deployment below. The aim is a **live production URL in M0**, then continuous work on `main` where every push deploys.

Input: $ARGUMENTS

## Stack

Unless the user or the spec says otherwise:

- **App:** the latest Next.js (App Router, Server Components, Turbopack), React, TypeScript strict, pnpm. **Read `node_modules/next/dist/docs/` before writing framework code**, because the APIs have moved since your training data (middleware is now `proxy.ts`, Cache Components and so on).
- **Database:** Postgres. Use Docker (`postgres:17`) locally and Neon in production, through Drizzle ORM and drizzle-kit with the `pg` driver on **both**. Don't use the Neon serverless driver, because it can't talk to local Docker.
- **Validation:** Zod 4, with generated table schemas from `drizzle-orm/zod`.
- **Auth, if needed:** Better Auth, email and password, with database sessions and database-backed rate limiting (in-memory storage doesn't work on serverless).
- **UI:** Tailwind CSS 4 (`@theme` tokens) and shadcn/ui, restyled to the spec's design system.
- **Tests:** Vitest for pure logic and database integrity. No Playwright.
- Pin the exact versions of anything pre-release.

## M0: live on day one

Do these in order, and confirm the project name, the region and the repo visibility with the user once before creating anything outward-facing.

1. **Scaffold:** `pnpm create next-app@latest`, then git init and the `/ludwig` bootstrap docs. Add `compose.yaml`, `.env.example`, `src/env.ts` (Zod-validated) and the gates script.
2. **Database client** (`src/db/index.ts`): one module-level `pg` `Pool` from `DATABASE_URL`, with `max: 5` and `idleTimeoutMillis: 5_000`. Under `process.env.VERCEL`, call `attachDatabasePool(pool)` from `@vercel/functions`. Rewrite `sslmode=require` to `verify-full` in the connection string.
3. **`drizzle.config.ts`** reads `DATABASE_URL_UNPOOLED` (DDL must not go through PgBouncer) and loads `.env.local` if it exists.
4. **Scripts:** `db:generate`, `db:migrate`, `db:seed` (an idempotent upsert, run with `--env-file-if-exists=.env.local`), `typecheck`, `lint`, `test`, `gates`.
5. **GitHub:** `gh repo create <name> --private --source . --push`.
6. **Vercel:** `vercel link`, connect git (`vercel git connect`), and add `vercel.json`:

   ```json
   {
     "$schema": "https://openapi.vercel.sh/vercel.json",
     "regions": ["lhr1"],
     "buildCommand": "pnpm db:migrate && pnpm db:seed && pnpm build"
   }
   ```

   Put the functions in the same region as the database (e.g. `lhr1` with Neon `aws-eu-west-2`). Every production deploy then migrates and seeds its own database, so nobody writes to production by hand.
7. **Neon through the Vercel Marketplace:** `vercel integration add neon` (or ask the user to add it in the dashboard if the CLI can't). It injects the pooled `DATABASE_URL` and the direct `DATABASE_URL_UNPOOLED` into each environment.
   - If previews will be used, **turn on branch-per-preview in the Vercel storage settings** (ask the user). Without it, previews share the production database.
8. **Secrets:** generate one for each environment that needs it and pipe it straight in, without ever printing it: `openssl rand -base64 32 | vercel env add BETTER_AUTH_SECRET production --sensitive`. Do the same for `preview` if previews are used, because a missing preview secret fails the build.
9. **Auth origins:** `BETTER_AUTH_URL` is the production domain. On previews, derive the base URL from `https://${VERCEL_URL}` and add it, together with `VERCEL_BRANCH_URL`, to `trustedOrigins`. Export that resolved base URL and use it anywhere the server builds an auth URL. Never read `env.BETTER_AUTH_URL` directly, because it is undefined on previews.
10. **Push and check once:** `git push`, then `vercel inspect <deployment-url> --logs --wait`. Confirm the build ran migrate → seed → build, then `curl -sI` the production domain and one API route. Give the user the live URL.

Then carry on with the `/ludwig` work loop.

## Working on main

- Every push to `main` is a production deploy, and every build costs time. **Batch pushes**: push at the end of a coherent chunk of work (a milestone item or two that pass the gates), not after every commit. After each push, check the deploy once with `vercel inspect --logs --wait`, and tell the user what's live to test.
- Migrations must be backward-compatible with the deploy that's still serving (add, then backfill, then remove later). Never edit a migration that has been pushed.
- Add a Vercel `ignoreCommand` that skips docs-only pushes once there are enough of them to matter.
- Previews are optional. Use a branch with a preview only for risky changes (auth, env, caching, migrations), and only when the user wants it.

## Platform tools

The Vercel and Neon CLIs and MCP plugins should be installed and authenticated. Go to the source rather than guessing, and don't ask the user for logs or dashboard checks you can do yourself.

- **Vercel:** build logs (`vercel inspect <url> --logs`), runtime logs (Vercel MCP `get_runtime_logs`), env var **names** (`vercel env ls`), and protected previews (`vercel curl --yes --deployment <url> <path>`).
- **Neon:** `neonctl branches list`, plus read-only SQL on any branch through Neon MCP `run_sql`. `main` is production.
- **Transient build failures** (`ETIMEDOUT`, `Connection terminated unexpectedly`, a Google Fonts fetch): `vercel redeploy <url> --no-wait`. Anything else, read the logs and fix it.
- **Needs the user's approval:** any write, delete or schema change on the production Neon branch outside a normal migrate-and-seed build, destructive Neon operations, and Vercel setting, domain or protection changes (except adding a missing generated secret as in step 8).
- **Never** print, decrypt or commit secrets or the contents of `.env*` files (other than `.env.example`), and never point local work or tests at Neon.
