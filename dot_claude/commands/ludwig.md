---
name: ludwig
description: Build an app continuously from a spec, with no tickets, PRs or browser automation. Bootstraps the spec, plan and guard rails on a new project, then works down the plan in one long session.
argument-hint: "[idea for a new project | what to work on next | blank to continue the plan]"
---

# ludwig

Build software the way the Ludwig project was built (spec first, risky plumbing first, pure logic tested first, guard rails that load automatically), but **work continuously in one session**. Don't write tickets ahead of time, don't orchestrate agents, and don't open a PR per change. The user tests by hand.

This command is stack-agnostic. For the Next.js + Vercel + Neon route to production, use `/ludwig-vercel`, which builds on this one.

Input: $ARGUMENTS

## 0. Work out where we are

- Read `CLAUDE.md`, `docs/SPEC.md` and `docs/PLAN.md` if they exist, plus `git log --oneline -15` and `git status`.
- **No spec yet:** this is a new project. Go to section 1.
- **Spec exists:** go to section 3. Start from the input if there is one; otherwise take the next unchecked item in `PLAN.md`. Pick up from the **Where we are** section in `PLAN.md` without re-deriving it.

## 1. Bootstrap (new projects only)

Ask the user only what changes the build: who it's for, the must-have features for v1, the non-goals, any stack or hosting preferences, and whether it needs accounts. Take one round of questions, then write the docs and get going. Fill gaps with sensible defaults and write them down as decisions.

1. **`docs/SPEC.md`: what we build.** It is the source of truth.
   - Goals and non-goals; the feature catalogue with exact rules; the information architecture (routes or screens).
   - The design system: tokens, type, motifs, and what's banned.
   - The technical architecture: stack with pinned versions, source layout, data model, auth, environment variables, deployment.
   - The quality bar and a **Decisions** list.
   - If the code later has to diverge from the spec, update the spec in the same commit.
2. **`docs/PLAN.md`: how and in what order.** Milestones made of checkbox items, each a vertical slice small enough to finish and commit in one go. Order:
   1. **M0 Foundations.** Prove the riskiest plumbing first (pre-release libraries, auth, hosting, the database) as time-boxed spikes. Every spike ends with a decision in the spec.
   2. **Design system before screens:** tokens, fonts and base components, so nothing gets styled twice.
   3. **Walking skeleton:** put **one** simple feature through every layer end to end (data, server, UI, persistence) and set the pattern.
   4. **Core logic engine-first:** pure functions, test-driven against hand-computed fixtures, before any UI touches them.
   5. **Breadth:** each further feature is a near-mechanical repeat of the skeleton's pattern.
   6. **Polish and launch.**

   Keep a **Where we are** section at the top: the date, what's done, what's next, open questions for the user.
3. **`CLAUDE.md`:** a short overview, the stack, the commands, the architecture layers and the **hard rules** (the few things that must never happen). Point to the spec rather than restating it.
4. **`.claude/rules/<area>.md`** with `paths:` frontmatter, for rules that only matter in part of the tree (database, auth, design system, domain logic). They load automatically when matching files are touched, which keeps `CLAUDE.md` short.
5. **Project skills** (`.claude/skills/<name>/SKILL.md`) only for a procedure that will repeat, such as scaffolding a new feature type or writing a trigger migration. Write one when a pattern is about to be used a second time, not before.

Then commit the docs and start M0.

## 2. Guard rails to build in M0

- **One local environment:** a `compose.yaml` for the database and other services, `.env.example` and env validation at startup, with a schema rather than raw `process.env` reads. Never point local work at production.
- **One gates command** that runs typecheck, lint, tests, build and any domain checker (e.g. a content verifier), and prints a single `PASS` line or `FAIL: <step>` with the last ~30 lines and the path of the full log. Short output saves tokens on every run.
- **Exact version pins** for pre-release or fast-moving dependencies. Read the docs that ship in `node_modules` for any library whose API has changed since your training data, before writing code against it.
- **Types derived from one source:** database tables → generated validation schemas → composed schemas. Never retype a shape that can be derived.
- **Content and fixtures as code:** curated data lives in the repo, is validated by schema and loaded by an idempotent seed script. Never insert it by hand.
- A minimal CI job that runs the gates on push. It's optional, but cheap.

## 3. The work loop

Repeat until the milestone is done, then carry straight on to the next one:

1. **Pick** the next unchecked `PLAN.md` item, or the user's request. Read the spec sections it touches and two or three existing files of the same kind, and match them.
2. **Build the vertical slice.** Pure logic gets its unit tests first. Schema changes get a migration plus an integration test for every constraint or trigger.
3. **Run the gates.** Fix the root cause of any failure. Never weaken a test to get green.
4. **Quick self-checks** only where they're cheap and decisive: a `curl` to an endpoint, a `psql` query, running a script. **No** Playwright, browser automation, screenshots or Lighthouse unless the user asks.
5. **Commit** in atomic Conventional Commits on the working branch (`main` unless the user says otherwise). No AI attribution.
6. **Tick the item** in `PLAN.md`, and update the spec if a decision was made.
7. **Keep going.** Don't stop after each item to report or ask permission.

Stop and ask only when:

- something contradicts the spec, or needs a product decision the docs don't cover;
- an action is destructive or outward-facing beyond the normal loop: production data, deleting things, paid services, new public repos or domains;
- you're blocked after a real attempt. Say what you tried and your best hypothesis.

At the **end of each milestone**, and when the session winds down:

- Update **Where we are** in `PLAN.md` and commit it.
- Give the user a short **manual test list**: the URLs or commands to run, what to click and what they should see. That is the hand-off for their testing, so keep it concrete.
- Push if the user has asked for pushes in this project, or if `/ludwig-vercel` is driving.

## 4. Token discipline

- No ticket files, per-change reports, evidence logs, review rounds or reviewer agents.
- Use subagents only for genuinely parallel, read-heavy research (for example "how does library X do Y in the installed version"), never for building and reviewing.
- Read logs only when the gates' tail isn't enough. Read big docs by section, not whole.
- Don't poll CI or deployments. Check once when it matters.
- Bug fixes the user reports go straight into the loop: reproduce cheaply, fix, test, commit.
