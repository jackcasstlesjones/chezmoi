---
name: changelog
description: Build or update CHANGELOG.md as a continuous, user-facing release history taken from the merges to the main branch.
---

# changelog

Maintain `CHANGELOG.md` as one continuous document: every release that has
landed on `main`, newest first, described in the words a person using the
product would use.

It is a product record, not an engineering log. A reader should be able to
scan a release and know what changed for them, without knowing a single file,
function, table or ticket exists.

Two modes, decided by what is already on disk:

- **No `CHANGELOG.md`** — build the history from the earliest release the user
  names, or from the first release that still means anything to a current user.
- **`CHANGELOG.md` exists** — document only the releases newer than the top
  entry. Existing sections are already published; do not rewrite them.

---

## 1. Establish the release boundaries

A release is a merge into `main`. Nothing else — not a tag, not a version
bump, not a deploy workflow run.

```bash
git fetch origin main
git log origin/main --first-parent --format='%h %ad %s' --date=short
```

`--first-parent` is what makes this work: it collapses each merged PR into one
line, so the output *is* the release list. Without it you get every commit on
every branch and the boundaries disappear.

Each first-parent commit that brings in real work is a release, dated by that
commit. Several PRs merged the same day are **one** release entry for that
date, not several.

Skip first-parent commits that are pure plumbing — back-merges of `main` into
`staging`, `staging` into `develop`, and similar chore merges. They carry no
new work forward; including them invents releases that never shipped.

## 2. Decide the window

Read the existing file first:

```bash
head -20 CHANGELOG.md          # newest documented release
grep -c '^## ' CHANGELOG.md    # how many sections exist now
```

The newest `##` heading is the low-water mark. Everything merged after it is
yours to write; everything at or before it is settled.

If the user asks for an earlier period than the file covers ("can we do June
too?"), that is a backfill: same process, but the new sections are **appended**
below the existing ones in date order, not prepended.

If the range is ambiguous, say which window you are about to cover in one line
and carry on. Do not stop to ask.

## 3. Read the work inside each release

For every release boundary, take the commits it brought in:

```bash
git log --no-merges --format='=== %h %s%n%b' <previous-release-sha>..<release-sha>
```

Read the bodies, not just the subjects. The subject tells you a thing changed;
the body usually tells you what a person would notice, and the bullet is
written from the second one.

Large releases run to hundreds of commits. Do not sample — a skimmed release
is where features go missing. Filter by scope in passes (`feat(`, `fix(`,
then everything else) if the volume is unwieldy, but cover all of it.

Where the commit history is thin, read the diff for the largest changes:

```bash
git diff --stat <previous-release-sha>..<release-sha>
git diff <previous-release-sha>..<release-sha> -- <path>
```

If you had to lean on diffs rather than messages for a release, say so in your
reply — the entry is less precise and the user should know which one.

## 4. Reconcile against what actually shipped

The changelog describes the state each release left the product in, not the
route the commits took. Three checks, in order of how often they bite:

**Reverts.** A revert inside a release cancels its own feature — neither gets a
bullet. A revert in a *later* release means the feature shipped, and the
removal belongs in the later entry, not the earlier one.

```bash
git log origin/main --format='%h %ad %s' --date=short --grep='^Revert' -i
```

Then settle it against the current tip rather than reasoning from the log:

```bash
git show origin/main:<path> | grep -n '<symbol>'
```

**Features completed across releases.** Work merged half-finished in one
release and finished in the next gets its bullet where a user could first use
it, not where the first commit landed.

**"Now" and "no longer" claims.** Every word implying a prior state is a claim
about the release *before* this one. Verify it there:

```bash
git show <previous-release-sha>:<path>
git grep -n '<symbol>' <previous-release-sha> -- src/
```

If the thing did not exist, or existed with no callers, there is no "before".
Describe what the release does and drop the contrast. A fix for a bug
introduced and fixed within the same release is invisible to users — it gets
no bullet at all.

## 5. Decide what earns a bullet

Include anything a user, an administrator or an operator could observe: a new
screen, field, action or dialog; changed behaviour, wording, limits, ordering
or permissions; a bug described by the symptom it used to cause; data that is
now kept, released, cascaded or cleaned up; something that used to be possible
and is now blocked, or the reverse.

Leave out anything with no observable effect: refactors, renames, type
changes, extracted helpers, formatting, lint and build fixes, dependency
bumps, generated files, config with no behaviour change, test-only changes,
and CI or deployment plumbing.

Two calls worth getting right. A permission change is functional — "only
owners and administrators can edit their organisation's articles" is exactly
what a reader needs. And a refactor that changes an error message is
functional: the refactor is invisible, the message is not.

## 6. Write the entry

Format, exactly:

```markdown
## 24 August 2026

**New**

- Network directory: browse everyone on the platform, with profile cards and continuous scrolling

**Changed**

- Funding marked as coming soon

**Fixed**

- Community posts page now loads
```

- `## D Month YYYY` — no version numbers, no "Unreleased", no `[1.2.0]`.
- `**New**`, `**Changed**`, `**Fixed**`, in that order. Omit any that is empty.
  `Changed` is for deliberate removals and reworkings, not fixes.
- One line per bullet, one change per bullet, no nesting, no sub-headings, no
  bold inside bullets, no commit hashes, no PR numbers, no file paths.
- No preamble, no overview paragraph, no "this release focuses on…". The file
  opens with its title and goes straight into the newest release.

Write in the product's vocabulary and its own spelling — if the interface says
"organisation", so does the changelog. Lead with the thing that changed, and
give a fix its consequence only when the symptom alone would puzzle someone.

Ten commits converging on one feature is one bullet. One commit fixing three
unrelated things is three. Keep related bullets adjacent — all the deletion
behaviour together, all the article-form behaviour together — without
labelling the groups; the ordering carries the structure.

## 7. Edit the file, do not regenerate it

A whole-file rewrite of a long changelog has truncated it in practice, and the
loss is silent. So:

- Prepend a new release by inserting above the current top `## ` heading.
- Append a backfill by inserting below the last existing section.
- Never rewrite sections you are not adding.

Then confirm nothing was lost:

```bash
grep -c '^## ' CHANGELOG.md     # expect previous count + sections added
tail -5 CHANGELOG.md            # the oldest release must still be intact
```

If the count is wrong, restore and redo the edit — do not patch over it.

## 8. Report

In your reply, not in the file:

- Which releases you added, with their dates and how many bullets each.
- The methodology in one line — first-parent merges to `main` as the release
  boundary, dated by the merge commit — so the dates can be audited.
- Anything you dropped as reverted or as intra-release churn, and what the
  previous release actually looked like.
- Any release you had to reconstruct from diffs rather than commit messages.
- Whether the file is still uncommitted, if it is.
