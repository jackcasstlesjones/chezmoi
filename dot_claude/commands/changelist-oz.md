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

## 0. How the platform ships

GitHub flow. A feature branches off `main`, is tested on that branch through its
own deployment preview, and merges back into `main`, which deploys immediately.
There is no `develop`, no `staging`, no release train and no back-merges.

Releases are therefore continuous — several on most days. **The unit in the
notes is the day, not the merge.** Everything that landed on `main` on one date
is one `## D Month YYYY` section. Never a section per merge, never a time of day
in a heading, never one date split across two sections.

A deployment preview on a feature branch ships nothing to the client. Only the
merge into `main` counts.

## 1. Find the releases

```bash
git -C $OZ fetch origin main
git -C $OZ log origin/main --first-parent --format='%h %cd %s' --date=short
```

Date by `%cd`, the committer date — when the work landed on `main`, which is
when it shipped. `%ad` is when the author first wrote it, which under squash
merges is often days earlier and would file the work under the wrong release.

`--first-parent` gives one line per merge into `main`. Merges arrive in two
shapes and both show up here: a squash commit carrying the PR title, and a true
merge commit where the branch was not squashed.

The release dates are that list reduced to its distinct dates:

```bash
git -C $OZ log origin/main --first-parent --format='%cd' --date=short | sort -u
```

The last commit of each day — the boundary you will diff to — is the first line
seen for each date, as the log runs newest first:

```bash
git -C $OZ log origin/main --first-parent --format='%cd %h' --date=short | awk '!seen[$1]++'
```

Not every date earns a section. A day carrying only chore, CI, deployment,
dependency or formatting merges shipped nothing the client can see — skip the
date rather than writing an empty heading.

## 2. Work out what is missing

```bash
head -20 $NOTES              # newest documented release
grep -n '^## ' $NOTES        # every release currently documented
```

The newest `##` heading is the low-water mark. Write a section for every
qualifying date after it.

That heading needs one check a release train never needed: **if the newest
documented date is one that is still taking merges — usually today, sometimes
yesterday — more will have landed since it was written.** Re-read that date's
full range and fold anything new into the existing section, in place. Never add
a second section for a date that already has one.

Dates before that are closed and have already gone to the client; do not rewrite
them. If asked to backfill an earlier period, the new sections are **appended**
in date order below the existing ones, not prepended.

## 3. Read the release

A day's range runs from the previous day's tip to that day's tip, both taken
from the `awk` list in step 1:

```bash
git -C $OZ log --no-merges --format='=== %h %s%n%b' <previous-day-tip>..<day-tip>
```

Equivalently, and easier to type for a run of days — `--since` and `--until`
filter on committer date, so they agree with the `%cd` dating above:

```bash
git -C $OZ log origin/main --no-merges --format='=== %h %s%n%b' \
  --since='2026-09-10 00:00' --until='2026-09-11 00:00'
```

Read the bodies, not just the subjects — the body is usually where the
user-visible consequence lives, and a squash commit's body is the whole branch's
commit list. Do not sample a busy day; a skimmed one is where features go
missing. Work through it in scope passes (`feat(`, then `fix(`, then the rest)
if the volume is unwieldy.

Where messages are thin, read the change itself:

```bash
git -C $OZ diff --stat <previous-day-tip>..<day-tip>
git -C $OZ diff <previous-day-tip>..<day-tip> -- <path>
```

## 4. Reconcile against what actually shipped

Each entry describes the state that day left the platform in, not the route the
commits took.

**Reverts.** This repo reverts in place and the log alone will mislead you.

```bash
git -C $OZ log origin/main --format='%h %cd %s' --date=short --grep='^Revert' -i
```

A revert on the same day as its feature cancels it — neither gets a bullet. A
revert on a *later* day means the feature shipped and the client saw it, so the
removal belongs in the later day's entry. Settle it against the current tip
rather than reasoning from the log:

```bash
git -C $OZ show origin/main:<path> | grep -n '<symbol>'
```

**Features finished across days.** Continuous merges mean a feature commonly
lands in pieces over several days. It gets its bullet on the day a user could
first use it, not the day the first piece merged.

**"Now" and "no longer".** Every word implying a prior state is a claim about
the day before. Verify it there:

```bash
git -C $OZ show <previous-day-tip>:<path>
git -C $OZ grep -n '<symbol>' <previous-day-tip> -- src/
```

If the thing did not exist, or existed with no callers, there is no "before" —
describe what shipped and drop the contrast. A bug introduced and fixed on the
same day is invisible to the client and gets no bullet; one introduced yesterday
and fixed today was live, and gets one.

## 5. What earns a bullet

In: new screens, fields, actions and dialogs; changed behaviour, wording,
limits, ordering or permissions; a bug named by the symptom it caused; data
that is now kept, cascaded or cleaned up; anything newly possible or newly
blocked.

Out: refactors, renames, type changes, formatting, lint and build fixes,
dependency bumps, generated files, tests, migrations with no visible effect,
and CI, preview-deployment or Cloudflare plumbing.

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

- `## D Month YYYY`. One heading per date, no version numbers, no times, no
  "Unreleased", no overview paragraph, no preamble under the release heading.
- `**New**`, `**Changed**`, `**Fixed**`, in that order; omit any that is empty.
  `Changed` is for deliberate removals and reworkings, not fixes.
- One line per bullet, one change per bullet. No nesting, no sub-headings, no
  bold inside a bullet.
- British spelling throughout — **organisation**, never organization, and never
  abbreviated to "org".
- Use the platform's own names for things: Starting Soon, Save Draft, Enable
  Comments, My Articles, Network, Undo Changes.
- Merges are not bullets. Four PRs converging on one feature in a day is one
  bullet; one PR fixing three unrelated things is three. Keep related bullets
  adjacent without labelling the groups.
- A quiet day is a short section, and that is fine — do not pad it, and do not
  merge it into a neighbouring date to make it look bigger.

## 7. Edit, do not regenerate

Rewriting this file whole has truncated it before, silently. Insert new sections
above the current top `## ` heading — or edit the top section in place when
topping up today's date — and leave everything else alone. Then check:

```bash
grep -c '^## ' $NOTES     # expect the previous count plus the dates you added
tail -5 $NOTES            # the 2 June 2026 entry must still be intact
```

A same-day top-up leaves that count unchanged; any other edit must raise it by
exactly the number of new dates. If the count is wrong, restore from git in the
roadmap repo and redo the edit.

`$OZ/CHANGELOG.md` is the same document and is currently byte-identical. If it
is present, apply the same edit to it so the two do not drift:

```bash
diff -q $OZ/CHANGELOG.md $NOTES
```

## 8. Report

In your reply, not in either file:

- The dates added, and how many bullets each; say separately which existing
  section you topped up, if any, and what you added to it.
- The methodology in one line — first-parent merges into `main`, grouped by the
  date they landed (committer date), chore-only days skipped — so the dates can
  be audited.
- Any date you skipped as shipping nothing visible, and why.
- Anything dropped as reverted or as same-day churn, and what the day before
  actually looked like.
- Any day reconstructed from diffs rather than commit messages.
- That `changelog/index.html` in the roadmap repo mirrors this file by hand and
  now needs the same dates adding — do not edit it unless asked.
- Neither file is committed by this command; both repos are left dirty.
