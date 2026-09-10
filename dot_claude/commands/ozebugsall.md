---
description: Fan out every Ready-for-Dev bug assigned to me into its own worktree and run the full bug-push pipeline in each
---

# Ozeaon Bug Fan-Out

Take every bug sitting in **Ready for Dev** assigned to Jack, give each one an isolated
worktree branched off `main`, and run `/ozebugspush` inside each one in parallel.

Run the phases in order. Do not skip Phase 2 — this ends with real PRs on the repo.

---

## Phase 0 — Preflight

Confirm the working directory is the Ozeaon repo, not chezmoi or anything else:

```bash
git rev-parse --show-toplevel
git remote get-url origin
```

If there is no `main` branch on the remote, stop and say so.

Fetch, so every worktree branches off current `main`:

```bash
git fetch origin main
```

Record the repo root — Phase 3 needs it.

---

## Phase 1 — Find the bugs

**Run this whole phase in a subagent.** The assignee filter returns well over a hundred
items and at most 10 survive the cap, so fetching the board into this context spends the
budget on rows that get discarded. Spawn one `general-purpose` agent and let only the
capped batch come back.

Prompt it with:

```
Load the Monday items tool:

  ToolSearch({ query: "select:mcp__claude_ai_monday_com__get_board_items_page", max_results: 1 })

Step 1 — candidates, without descriptions. Descriptions across the whole board overflow the
tool's token limit, so leave them out until the batch is capped:

  get_board_items_page({
    boardId: 5015597434,
    filters: [
      { columnId: "multiple_person_mky2f1n9", compareValue: ["person-90359998"], operator: "any_of" }
    ],
    includeColumns: true,
    includeItemDescription: false,
    columnIds: ["name", "item_id", "bug_status", "priority_1"],
    limit: 200
  })

Filter client-side to items whose `bug_status` (Phase) is exactly "Ready for Dev" — do not
filter on the status label in the query, the label ids drift. Sort by `priority_1`:
Critical -> High -> Medium -> Low -> none. Cap at 10.

Step 2 — descriptions for the survivors only. Query again with
`includeItemDescription: true`, filtered to just the capped `item_id`s.

If Monday is not authenticated, report exactly that and stop.

Report back ONLY the following. No board statistics, no account of what you discarded, no
commentary on the tickets:

  - one line per bug: `BOZN-### | priority | title`
  - each bug's description below its id, verbatim, or `(no description)`
  - a final line: `N ready for dev, M over the cap`
```

If the agent reports zero bugs, say so and stop — nothing to do. If it reports that Monday
is not authenticated, tell the user to run `/mcp` and pick **claude.ai monday.com**.

---

## Phase 2 — Announce the batch

Print the batch as a table: `BOZN-### — title — Priority`, plus the branch name each will get.

**If a human is driving** (you were invoked interactively): ask for a go-ahead and offer to
drop any from the batch. Do not start Phase 3 without an explicit yes.

**If this is an unattended run** (cron, routine, `claude -p`, or the prompt says
`UNATTENDED`): skip the confirmation and go straight to Phase 3. The safety net is that
everything lands as a **draft** PR on its own branch — nothing merges, nothing touches
`main`. Agents that hit ambiguity stop before committing, per Phase 4.

---

## Phase 3 — One worktree per bug

For each bug, build a branch name that **contains the ticket id in lowercase**:

```
fix/bozn-123-<slug>
```

where `<slug>` is the first 4–5 words of the title, kebab-cased, lowercase, non-alphanumerics
stripped. The `bozn-123` part is load-bearing — `/ozbugs` reads the ticket id back out of the
branch name, which is what lets `/ozebugspush` run unmodified inside the worktree.

Create each worktree from the repo root, explicitly based on `origin/main`:

```bash
git worktree add -b fix/bozn-123-<slug> .claude/worktrees/bozn-123 origin/main
```

The explicit `origin/main` matters: the `worktree.baseRef` setting is `head`, so without it
the worktree would branch off whatever happens to be checked out.

If the branch or worktree path already exists, skip that bug and report it — never
force-delete existing work.

### Bootstrap each worktree

A fresh worktree has no dependencies and no env files, so review and typecheck will fail.
For each worktree, from the repo root:

```bash
# env files are gitignored, so carry them over
for f in .env .env.local .env.development .env.development.local; do
  [ -f "$f" ] && cp "$f" .claude/worktrees/bozn-123/
done
```

Then install dependencies in the worktree using whatever the lockfile indicates
(`pnpm-lock.yaml` → `pnpm install`, `package-lock.json` → `npm install`, `yarn.lock` → `yarn`).
Run these in the background and let them all finish before Phase 4 — installs are slow and
independent.

If an install fails, drop that bug from the batch and report it rather than handing an
agent a broken tree.

---

## Phase 4 — Run the pipeline in each worktree

Spawn one agent per bug with `subagent_type: "claude"`, all in the same message so they
run in parallel.

**Do not pass `isolation: "worktree"`** — that would create a second worktree with a
generated branch name off HEAD, which breaks both the ticket-id-in-branch trick and the
`main` base. The worktrees already exist; the agent just enters one.

Prompt template for each agent:

```
`EnterWorktree` is a deferred tool, so your first two actions are:

  1. ToolSearch({ query: "select:EnterWorktree", max_results: 1 })
  2. EnterWorktree({ path: "<abs path>/.claude/worktrees/bozn-123" })

Everything after that happens inside that worktree — never run `git worktree add`, never
`cd` out, never touch another worktree.

You are fixing BOZN-123: <title>
Priority: <priority>
<description, if the Monday item had one>

Now invoke the pipeline as a skill — `Skill({ skill: "ozebugspush" })`. It is a skill, not
text: writing `/ozebugspush` in your reasoning runs nothing. Same for the skills it calls
in turn (`ozbugs`, `commit`, `oz-review`, `new-pr`) — each is a `Skill()` call.

Run it with these changes:

- Phase 6: open the PR as a DRAFT — `gh pr create --draft --base main ...`
- Phase 6.5: SKIP. Do not request reviewers on a draft.
- Phase 7: SKIP. Monday moves the ticket automatically off the PR now.

If the ticket is ambiguous, under-specified, or you cannot make the fix confidently, STOP
before Phase 3 (commit). Leave the worktree as it is and report what blocked you and what
you'd need to know. Do not open a speculative PR.

Report back: the commits you made, the draft PR URL, or the reason you stopped.
```

---

## Phase 5 — Report

Once every agent is back, print one table:

| Bug      | Branch             | Result                             |
| -------- | ------------------ | ---------------------------------- |
| BOZN-123 | `fix/bozn-123-...` | draft PR url                       |
| BOZN-124 | `fix/bozn-124-...` | blocked — needs clarification on X |

Then a one-line summary: how many shipped as draft PRs, how many are blocked, and how many
were skipped from the cap.

Leave every worktree on disk — the user reviews them. Do not clean up.

**If this was an unattended run**, also fire a push notification so the batch does not sit
unnoticed. `PushNotification` is deferred — `ToolSearch({ query: "select:PushNotification",
max_results: 1 })` first, then send one line: how many draft PRs opened, how many blocked.

---

## Running unattended

For cron / routine / `claude -p` invocations, the pipeline needs network and git without
prompts. Grant exactly what it uses, nothing wider:

```bash
claude -p "/ozebugsall UNATTENDED" \
  --allowedTools 'Bash(git *)' 'Bash(gh *)' 'Bash(pnpm *)' 'Bash(npm *)' \
                 Read Edit Write Agent Skill ToolSearch \
                 'mcp__claude_ai_monday_com__*'
```

Two things bite in headless mode if you leave them at defaults:

- **Network approval.** The Bash sandbox pre-allows no domains, so the first `git push`,
  `gh pr create`, or dependency install asks for host approval — and there is nobody to
  answer. Pre-allow the hosts in `sandbox.network.allowedDomains`: `github.com`,
  `*.github.com`, `registry.npmjs.org`.
- **`gh` under the sandbox.** It can fail TLS verification; if so, list `gh *` in
  `sandbox.excludedCommands`.

MCP tools (the Monday calls) run under the permission system, not the Bash sandbox, so
Phase 1 is unaffected by either.

---

## Reference

| Field           | Value                      |
| --------------- | -------------------------- |
| Board ID        | `5015597434`               |
| Bug prefix      | `BOZN`                     |
| Jack's user id  | `person-90359998`          |
| Assignee column | `multiple_person_mky2f1n9` |
| Phase column    | `bug_status`               |
| Priority column | `priority_1`               |
| Item ID column  | `item_id`                  |
| Batch cap       | 10                         |
| PR base         | `main`                     |
