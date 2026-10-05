---
description: Full bug-fix push pipeline — pull ticket, implement fix, commit, review, PR into main, confirm Monday sync
---

# Ozeaon Bug Push Pipeline

Run each phase in order. Do not skip a phase. Do not combine phases.

---

## Phase 1 — Pull the ticket

Invoke `/ozbugs` to fetch the BOZN ticket for this branch from the Monday Bugs Queue. Print the full ticket detail (title, phase, status, priority, assignees, description). This is the source of truth for what needs to be fixed.

---

## Phase 2 — Implement the fix

Using the ticket details from Phase 1, implement the fix. Read the relevant code, understand the bug, and make the necessary changes. Do not commit yet — that happens in Phase 3.

If the fix is already fully implemented (i.e. you were invoked mid-pipeline or the work is done), skip this phase and proceed to Phase 3.

---

## Phase 3 — Commit current work

Invoke `/commit` to stage and commit all changes in atomic conventional commits. Each logical change gets its own commit. Do not squash unrelated changes together.

---

## Phase 4 — Code review

Invoke `/oz-review` to review the full diff against `main`. Work through every finding:

- 🔴 Critical — fix immediately, then re-commit before continuing
- 🟡 Warning — fix and re-commit if the fix is unambiguous; otherwise flag it in the PR description
- 🟢 Suggestion — apply only if it's a one-liner with zero risk; otherwise note it

If any fixes were made in this phase, invoke `/commit` again to commit them before moving to Phase 5.

---

## Phase 5 — Write the PR description

Invoke `/new-pr` to generate the PR description and save it to `pr-description.md`.

End the description with a plain `Closes BOZN-<n>` line — not in backticks or a code block. That line is the only thing that links the PR to its Monday item; an id in the branch name or a commit message is ignored.

## Phase 6 — Create the PR

Use `gh pr create` with the content from `pr-description.md` as the body. Target `main` — there is no `develop` or `staging`. Every PR into `main` gets its own preview Worker and Supabase branch (`docs/deployment-previews.md`).

**PR title**: `fix(<scope>): <what changed>` — conventional commit style, under 70 chars.

```bash
gh pr create --title "..." --base main --body-file pr-description.md
```

Print the PR URL once created.

---

## Phase 6.5 — Request review

Request GitHub reviews from `maxitect` and `right-handed` on the PR created in Phase 6:

```bash
gh pr edit --add-reviewer maxitect,right-handed
```

Confirm both reviewers were added.

---

## Phase 7 — Confirm the Monday sync

Do not move the ticket by hand. `.github/workflows/monday-sync.yml` moves the BOZN item to **Code Review** when the PR opens and writes the PR URL into its GitHub Link field, then on to **QA** on approval and **Fixed** on merge (`docs/workflows.md` § Monday tickets).

Check the PR for the sync job's comment naming the ticket and the column it landed in:

```bash
gh pr view --comments
```

If no comment appears, or the **Ticket ID** check fails, the `Closes BOZN-<n>` line is missing or malformed — fix the PR description rather than moving the ticket manually.

---

## Done

Report in one sentence: commits made, PR URL, and the column the sync moved the ticket to.
