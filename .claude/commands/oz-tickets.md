---
description: Create OZEAON Monday tickets from a markdown ticket file — one item per H2 section, acceptance criteria in the item description, spec/Figma links at the top
argument-hint: "<ticket-file.md> [spec-url] [figma-url]"
---

# OZEAON — Markdown → Monday tickets

Turn a markdown ticket file into items on the **Tasks** board. One item per `##` section; the
checklist bullets under it become that item's acceptance criteria.

Board `5015597431` · group `topics` (All Tasks) · **Ready for Dev is a label on the `task_status`
(State) column, not a group.** Re-read `get_board_info` if a call rejects a label or column id.

## Item name

`[Area #n] <section heading>` — Area from the file's `#` title (e.g. `Notifications`), `n` the
section's number, then the heading with its spec/AC code stripped:

| Section heading                   | Item name                          |
| --------------------------------- | ---------------------------------- |
| `## 2. Overlay read path (CMP-012)` | `[Notifications #2] Overlay read path` |

Spec and AC codes stay in the body — never in the title.

## Create the items

```
create_items(boardId: 5015597431, items: [
  { name: "[Area] …", groupId: "topics", columnValues: "{\"task_status\":{\"label\":\"Ready for Dev\"}}" }
])
```

Leave owner, priority, epic, sprint and estimates unset — triage sets those. Keep the returned item
ids; the descriptions are a second pass.

## Set the description

The description lives in the `monday_doc_v2` column, which is type `direct-doc` — **`create_doc`
fails on it**. Use the mutation:

```
all_api_write(
  query: "mutation ($itemId: ID!, $md: String!) { set_item_description_content(item_id: $itemId, markdown: $md) { block_ids } }",
  variables: { itemId: "<id>", md: "<markdown>" }
)
```

It replaces the whole description, so it is also how you re-sync a ticket after the file changes.

## Description format

```markdown
**Spec:** <spec-url>

**Figma:** <figma-url>

**Sequence:** <n> of <total>

## Acceptance criteria

- <bullet text> *(AC refs)*
```

- Same two links at the top of every ticket in the batch.
- `Sequence` is the section's number in the file and the batch size — the ordering is only implicit
  in the markdown headings, so it has to be stated on the ticket. Order only; do not infer or add
  dependencies between tickets.
- Strip the `- [ ]` checkbox; keep the bullet wording verbatim otherwise.
- Convert the file's `_(…)_` AC references to `*(…)*` — Monday's importer wants asterisks.
- Carry over any preamble line under the `#` title as a plain paragraph between the links and the
  `## Acceptance criteria` heading; drop it when the file drops it.
- Expand `org` → `organization` in prose.

## Finish

Report a table of ticket id (`TOZN-…`), name and item URL, plus anything left unset and any wording
you changed from the file.
