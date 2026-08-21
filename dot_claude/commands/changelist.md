---
name: changelist
description: Summarise everything a branch changed as a flat, functional bullet list written from the user's point of view.
---

# changelist

Produce a flat bullet list of what a branch changed, described by what a
person using the product would notice — not by what the code does.

The output is the whole deliverable. No headings, no sections, no bold, no
nesting, no commit hashes, no file paths. Just bullets.

## 1. Find the comparison point

Never assume `main`. Determine the base branch in this order, stopping at the
first that resolves:

1. What the user named in their request.
2. The PR's base, if one exists: `gh pr view --json baseRefName -q .baseRefName`
3. The repo's default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
4. Whichever of `develop`, `main`, `master` exists: `git rev-parse --verify <name>`

Many repos develop against `develop` and release from `main`; picking the wrong
one either buries the branch's work in months of unrelated history or misses
half of it. If two candidates are plausible, ask which one — one short question
is cheaper than a wrong list.

A git worktree changes nothing here. Branch refs resolve normally.

## 2. Read the commits, bodies included

```bash
git log <base>..HEAD --pretty=format:"=== %h %s%n%b" --no-merges
git diff <base>...HEAD --stat
```

Subjects alone are not enough. The body is where the reason lives, and the
reason is usually the only thing that tells you what a user would actually
notice. A subject like `fix(api): guard partial updates` becomes a useful
bullet only once the body explains that omitting a field used to wipe it.

Read every body. Do not sample.

If bodies are thin or absent across the branch, fall back to reading the diff
itself — `git diff <base>...HEAD -- <path>` on the files with the largest
change counts. Say so in your reply, since the list will be less precise.

## 3. Reconcile against the final state

Branches contradict themselves. Work gets added, reverted, redone, or
superseded three commits later. The list describes **where the branch ended
up**, not the route it took.

When a commit's claim might not have survived, check the final diff before
writing a bullet for it. If two commits conflict, the later one wins. If a
feature was added and then removed, it gets no bullet at all.

Watch for commits from other sessions or authors that landed on the branch
while you were not looking — `git log <base>..HEAD --format="%h %an %ad %s"`.
Include them if they are part of the branch's work; flag them separately in
your reply if they look unrelated or unexpected.

## 4. Verify every "before" against the base

This is the error this task fails on most often, so hunt it deliberately.

A commit that fixes something an earlier commit on the same branch introduced
reads *exactly* like a commit that fixes something on the base. The message
cannot tell you which. Only the base can.

So treat every word implying a prior state — "now", "no longer", "instead of",
"previously", "rather than", "replacing", "used to" — as a claim about the base
branch, and verify it there:

```bash
git show <base>:<path>                   # did it exist at all?
git grep -n "<symbol>" <base> -- src/    # existed, but was it reachable?
git show <base>:<path> | grep -n "<x>"   # what did it actually do?
```

Three failure shapes, each of which produced a confidently wrong bullet in
practice:

- **The feature is entirely new.** "Changing the password now signs you out of
  every other session" — when the base had no password-change flow at all.
  There is no "now". Describe what the feature does, without the contrast.
- **The fix repairs this branch's own bug.** "Deleting an account is no longer
  blocked when its content has been reposted" — when the blocking constraint
  was added by this branch and account deletion did not exist on the base.
  Invisible to anyone comparing against the base. Drop it entirely.
- **The old code was unreachable.** "Replaces the old soft delete that could be
  undone by logging back in" — when the soft-delete function had no callers
  anywhere. Dead code is not prior behaviour. Grep for callers before calling
  anything replaced.

The test: say the bullet's implied "before" out loud as a sentence, then ask
whether someone using the base branch could have experienced it. If not,
rewrite the bullet to describe only what the branch now does.

Intra-branch churn is normal and often accounts for a fifth of the commits.
Expect to drop bullets here, not just reword them.

## 5. Decide what earns a bullet

Include anything a user, an admin, or an operator could observe:

- New capability, screen, field, action, dialog
- Changed behaviour, wording, limit, ordering, permission
- A bug that used to bite, described by the symptom
- Data that is now kept, released, cascaded, or cleaned up
- Anything that used to be possible and is now blocked, or vice versa

Leave out anything with no observable effect:

- Pure refactors, renames, type-only changes, extracted helpers
- Formatting, comment edits, lint and build fixes
- Dependency bumps, generated files, config with no behaviour change
- Test-only changes, unless the user asked for engineering-facing notes

Two judgement calls worth getting right:

**A permission fix is functional.** "Only owners and admins can now do X —
previously any signed-in user could" is exactly the kind of thing a reader
needs. Do not file it under security and drop it. It still has to survive
section 4: check the base really did allow it.

**A refactor that changes an error message is functional.** The user sees the
message. The refactor is invisible; the message is not.

## 6. Write the bullets

One change per bullet. Lead with the verb: Added, Implemented, Fixed, Removed —
or the subject followed by "now", but only once section 4 has confirmed there
is a real "before" to contrast against.

Write in the vocabulary of the product, not the codebase. Never name a
function, file, table, column, endpoint, component, or ticket. If a bullet
cannot be written without one of those, it is an implementation detail and
belongs in section 5's exclusion list.

Give a fix its consequence when the symptom alone would puzzle a reader. One
clause, not a paragraph:

> Fixed the settings page silently rewriting an organisation's slug on load,
> which changed its public URL on the next save

Keep related bullets adjacent — all the deletion behaviour together, all the
form fields together — without labelling the groups. Ordering carries the
structure; headings would violate the format.

Match the product's own spelling and terminology, including regional spelling.
If the codebase and UI say "organisation", the list says "organisation".

Split a bullet doing two jobs. Merge bullets that restate each other at
different altitudes: a general statement plus its special case is one bullet,
unless the special case is itself surprising.

Aim for one bullet per user-visible change, however many commits produced it.
Ten commits converging on one feature is one bullet. One commit fixing three
unrelated things is three.

## 7. Deliver

Write to the file the user named, or `list.md` in the repo root if they did
not name one. Plain markdown bullets, nothing else in the file.

Then, in your reply and not in the file, state:

- What you deliberately left out and why — one sentence, so the user can tell
  the difference between "not included" and "missed"
- Which bullets you dropped as intra-branch churn, and what the base actually
  looked like
- Any superseded work you collapsed, naming the final behaviour
- Anything on the branch that looked out of place

## Example

Not this — implementation vocabulary, and the reader learns nothing:

```
- Refactored deleteUserAccount() to call the delete_user_account RPC
- Added logo_image_id and cover_image_id to organizationSettingsSchema
- Fixed FK constraint posts_post_tag_fkey to ON DELETE SET NULL
```

Not this either — product vocabulary, but every bullet invents a "before" that
never shipped:

```
- Implemented permanent account deletion, replacing the old soft delete that could be undone by logging back in
- Deletion is no longer blocked when someone has reposted the content
- Changing the password now signs the user out of all other sessions
```

The first describes a function with no callers. The second fixes a constraint
this branch added. The third contrasts against a flow that did not exist.

This:

```
- Added permanent account deletion; there was previously no way for a user to delete their account at all
- Added a change password dialog requiring the current password before setting a new one, which also signs the user out of every other session
- Posts that attach a project, article, organisation or another post now show an "Unavailable" placeholder in its place once that content is deleted, instead of the attachment silently vanishing
```
