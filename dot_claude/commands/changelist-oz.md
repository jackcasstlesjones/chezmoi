---
name: changelist-oz
description: Update the OZEAON release notes at ~/coding/ozeaon-roadmap/updates.md from the releases shipped to main in ozeaon-v2.
---

# changelist-oz

Read the releases that have shipped to `main` in the OZEAON platform repo and
write them into the client-facing release notes.

- **Source of truth:** `/home/jack/tandemhub/ozeaon-v2` — the `main` branch only.
- **Output:** `/home/jack/coding/ozeaon-roadmap/updates.md`

Both are fixed. Run this from either repo — every git command names its repo
with `-C`, so the working directory does not matter:

```bash
OZ=/home/jack/tandemhub/ozeaon-v2
NOTES=/home/jack/coding/ozeaon-roadmap/updates.md
```

`updates.md` is read by the client. It is a product record, not an engineering
log: no file names, no function names, no table or column names, no ticket
references, no PR numbers, no commit hashes.

---

## 1. Find the releases

```bash
git -C $OZ fetch origin main
git -C $OZ log origin/main --first-parent --format='%h %ad %s' --date=short
```

`--first-parent` collapses each merged PR to one line, so the output *is* the
release list.

Work flows `develop` → `staging` → `main`. Only the merge into `main` ships.
Two kinds of first-parent commit are **not** releases:

- `chore(ci): backmerge main into staging`, `chore(ci): backmerge staging into
  develop` — these push code backwards, they ship nothing.
- Any other pure-chore merge carrying no product change.

Several PRs merged on the same day are **one** release entry for that date.
The big ones arrive that way: the 24 August release was 13 PRs and 290 commits
landing together.

## 2. Work out what is missing

```bash
head -20 $NOTES              # newest documented release
grep -n '^## ' $NOTES        # every release currently documented
```

The newest `##` heading is the low-water mark — write only what merged after
it. Existing sections have already gone to the client; do not rewrite them.

If asked to backfill an earlier period, the new sections are **appended** in
date order below the existing ones, not prepended.

## 3. Read the release

For each undocumented release boundary:

```bash
git -C $OZ log --no-merges --format='=== %h %s%n%b' <previous-release-sha>..<release-sha>
```

Read the bodies, not just the subjects — the body is usually where the
user-visible consequence lives. Do not sample a large release; a skimmed one
is where features go missing. Work through it in scope passes (`feat(`, then
`fix(`, then the rest) if the volume is unwieldy.

Where messages are thin, read the change itself:

```bash
git -C $OZ diff --stat <previous-release-sha>..<release-sha>
git -C $OZ diff <previous-release-sha>..<release-sha> -- <path>
```

## 4. Reconcile against what actually shipped

Each entry describes the state that release left the platform in, not the
route the commits took.

**Reverts.** This repo reverts in place and the log alone will mislead you.

```bash
git -C $OZ log origin/main --format='%h %ad %s' --date=short --grep='^Revert' -i
```

A revert inside a release cancels its own feature — neither gets a bullet. A
revert in a *later* release means the feature shipped, and the removal belongs
in the later entry. Settle it against the current tip rather than reasoning
from the log:

```bash
git -C $OZ show origin/main:<path> | grep -n '<symbol>'
```

**Features finished across releases.** A half-landed feature gets its bullet in
the release where a user could first use it.

**"Now" and "no longer".** Every word implying a prior state is a claim about
the *previous* release. Verify it there:

```bash
git -C $OZ show <previous-release-sha>:<path>
git -C $OZ grep -n '<symbol>' <previous-release-sha> -- src/
```

If the thing did not exist, or existed with no callers, there is no "before" —
describe what the release does and drop the contrast. A bug introduced and
fixed inside one release is invisible to the client and gets no bullet.

## 5. What earns a bullet

In: new screens, fields, actions and dialogs; changed behaviour, wording,
limits, ordering or permissions; a bug named by the symptom it caused; data
that is now kept, cascaded or cleaned up; anything newly possible or newly
blocked.

Out: refactors, renames, type changes, formatting, lint and build fixes,
dependency bumps, generated files, tests, migrations with no visible effect,
and CI or Cloudflare deployment plumbing.

A permission change is functional and belongs in ("organisation owners and
administrators can edit and delete their organisation's articles"). So does a
refactor that changes an error message the user reads.

## 6. Write it

`updates.md` opens with `# OZEAON Changelog`, then releases newest first:

```markdown
## 24 August 2026

**New**

- Network directory: browse everyone on the platform, with profile cards and continuous scrolling

**Changed**

- Funding marked as coming soon

**Fixed**

- Community posts page now loads
```

- `## D Month YYYY`. No version numbers, no "Unreleased", no overview
  paragraph, no preamble under the release heading.
- `**New**`, `**Changed**`, `**Fixed**`, in that order; omit any that is empty.
  `Changed` is for deliberate removals and reworkings, not fixes.
- One line per bullet, one change per bullet. No nesting, no sub-headings, no
  bold inside a bullet.
- British spelling throughout — **organisation**, never organization, and never
  abbreviated to "org".
- Use the platform's own names for things: Starting Soon, Save Draft, Enable
  Comments, My Articles, Network, Undo Changes.
- Ten commits converging on one feature is one bullet; one commit fixing three
  unrelated things is three. Keep related bullets adjacent without labelling
  the groups.

## 7. Edit, do not regenerate

Rewriting this file whole has truncated it before, silently. Insert the new
section above the current top `## ` heading and leave everything else alone.
Then check:

```bash
grep -c '^## ' $NOTES     # expect the previous count plus what you added
tail -5 $NOTES            # the 2 June 2026 entry must still be intact
```

If the count is wrong, restore from git in the roadmap repo and redo the edit.

`$OZ/CHANGELOG.md` is the same document and is currently byte-identical. If it
is present, apply the same edit to it so the two do not drift:

```bash
diff -q $OZ/CHANGELOG.md $NOTES
```

## 8. Report

In your reply, not in either file:

- The releases added, their dates, and how many bullets each.
- The methodology in one line — first-parent merges into `main`, dated by the
  merge commit, back-merges excluded — so the dates can be audited.
- Anything dropped as reverted or as within-release churn, and what the
  previous release actually looked like.
- Any release reconstructed from diffs rather than commit messages.
- That `changelog/index.html` in the roadmap repo mirrors this file by hand and
  now needs the same release adding — do not edit it unless asked.
- Neither file is committed by this command; both repos are left dirty.
