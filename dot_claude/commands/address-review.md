---
description: Fetch PR review comments, address them, commit + push, re-request review
---

# Address PR Review

Run each phase in order. Do not skip a phase.

---

## Phase 1 — Fetch PR comments

Get the PR for the current branch and collect all review feedback:

```bash
# Get PR number and reviewer list
gh pr view --json number,url,reviewRequests,reviews,headRefName

# Get all inline review comments (diff-level)
gh pr view --json reviewThreads --jq '.reviewThreads[] | select(.isResolved == false) | {path: .path, line: .line, body: (.comments[0].body), author: (.comments[0].author.login)}'

# Get top-level PR comments
gh pr comment list
```

Print a numbered list of every unresolved comment: file, line (if applicable), author, and the comment body. If there are no comments, report that and stop.

---

## Phase 2 — Assess and address each comment

Work through the list from Phase 1 one by one.

For each comment:
- Read the relevant file and line(s)
- Decide: **fix**, **skip** (already resolved, stylistic preference, question only), or **note** (needs discussion, skip with explanation)
- Apply fixes directly in the code — do not commit yet

After working through all comments, print a brief summary: what was fixed, what was skipped and why.

---

## Phase 3 — Commit changes

Invoke `/commit` to stage and commit all changes in atomic conventional commits.

If nothing was changed (all comments were skipped), report that and stop — do not push or re-request review.

---

## Phase 4 — Push

```bash
git push
```

Confirm the push succeeded.

---

## Phase 5 — Re-request review

Get the list of reviewers who left comments, then re-request review from each:

```bash
# Get reviewer logins from the reviews
gh pr view --json reviews --jq '[.reviews[].author.login] | unique | .[]'

# Re-request review from each (run once per reviewer login)
gh api --method POST \
  repos/{owner}/{repo}/pulls/{number}/requested_reviewers \
  --field 'reviewers[]={login}'
```

Use `gh pr view --json headRepository` to resolve `{owner}/{repo}` and `--json number` for `{number}`.

Confirm who review was re-requested from and print the PR URL.

---

## Done

Report in one sentence: what was fixed, commits made, and who was re-requested for review.
