---
description: Full bug-fix push pipeline — pull ticket, implement fix, commit, review, PR, move Monday ticket
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

Invoke `/oz-review` to review the full diff against `develop`. Work through every finding:

- 🔴 Critical — fix immediately, then re-commit before continuing
- 🟡 Warning — fix and re-commit if the fix is unambiguous; otherwise flag it in the PR description
- 🟢 Suggestion — apply only if it's a one-liner with zero risk; otherwise note it

If any fixes were made in this phase, invoke `/commit` again to commit them before moving to Phase 5.

---

## Phase 5 — Write the PR description

Invoke `/new-pr` to generate the PR description and save it to `pr-description.md`.

## Phase 6 — Create the PR

Use `gh pr create` with the content from `pr-description.md` as the body. Target `develop`.

**PR title**: `fix(<scope>): <what changed>` — conventional commit style, under 70 chars.

```bash
gh pr create --title "..." --base develop --body "$(cat pr-description.md)"
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

## Phase 7 — Move the Monday ticket

Load `mcp__claude_ai_monday_com__change_item_column_values` via ToolSearch, then move the BOZN item (board `5015597434`) from its current phase to **Review & Deploy**:

```json
{ "bug_status": { "label": "Review & Deploy" } }
```

Confirm the update was successful and print the Monday item URL.

---

## Done

Report in one sentence: commits made, PR URL, and that the ticket was moved to Review & Deploy.
