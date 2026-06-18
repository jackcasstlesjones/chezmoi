---
description: Pull the Monday.com ticket for the current branch and begin work
---

# Begin work on the current ticket

## 1. Extract ticket ID from the branch

Run `git branch --show-current` and find a ticket ID matching `/[a-z]+[-_]?\d+/i` — most commonly `TOZN-###` (case-insensitive, `tozn-327` in `feat/tozn-327-home-page-1-ui` → `TOZN-327`).

If no match, fall through to **Step 5** (list open tickets).

## 2. Load Monday tools and fetch the ticket

The Monday MCP tools are deferred. Load them in one call:

```
ToolSearch select:mcp__claude_ai_monday_com__get_board_items_page
```

Then query board `5015597431` (OZEAON Dev) with a filter on the `item_id` column:

```
get_board_items_page({
  boardId: 5015597431,
  filters: [{ columnId: "item_id", compareValue: "TOZN-327", operator: "any_of" }],
  includeColumns: true,
  includeItemDescription: true,
  columnIds: ["task_status", "task_priority", "color_mkynjgea", "task_type", "task_epic", "task_owner", "multiple_person_mkwz2e5d", "item_id", "monday_doc_v2"]
})
```

If Monday is not authenticated, tell the user to run `/mcp` and pick **claude.ai monday.com**.

## 3. Fetch the linked spec (if any)

The Monday description usually contains a single link to a Google Doc with the real requirements. If you see a `docs.google.com/document/d/<ID>` URL in the description blocks, extract `<ID>` and load the Drive tool:

```
ToolSearch select:mcp__claude_ai_Google_Drive__read_file_content
```

Then call `read_file_content({ fileId: "<ID>" })`. If Google Drive is not authenticated, tell the user to run `/mcp` and pick **claude.ai Google Drive**.

## 4. Brief and begin

Output a tight summary — no full document dumps:

- Ticket: **{item_id} — {title}**
- Status / Priority / Type / Epic / Assignees
- A condensed checklist of the spec from the Google Doc (bullets, not prose)

Then **start the work**:

- If `task_status` is **Dev In Progress**, **Ready for Dev**, or unset → begin implementing right away
- If status is **Review & Deploy** / **QA** / **Done** → say so and ask what they want to do (audit current state? extend? move to a different ticket?)
- If status is **Backlog** or stale → flag it before diving in

## 5. No ticket ID in the branch — list options

Query the board for items assigned to Jack and not Done:

```
get_board_items_page({
  boardId: 5015597431,
  filters: [
    { columnId: "multiple_person_mkwz2e5d", compareValue: ["person-90359998"], operator: "any_of" },
    { columnId: "task_status", compareValue: [1], operator: "not_any_of" }
  ],
  filtersOperator: "and",
  includeColumns: true,
  columnIds: ["task_status", "task_priority", "item_id", "color_mkynjgea"]
})
```

Group by status (Dev In Progress → Ready for Dev → Review & Deploy → QA → Backlog) and ask which to pick up. Prefer finishing Dev In Progress before opening new work.

## Reference

| Field | Value |
|---|---|
| Board ID | `5015597431` |
| Workspace | OZEAON Dev |
| Task prefix | `TOZN` |
| Jack's Monday user ID | `90359998` (filter format `person-90359998`) |
| Owner column | `task_owner` |
| Assignee column | `multiple_person_mkwz2e5d` |
| Status column | `task_status` (Done = label id `1`) |
| Type column | `color_mkynjgea` |
| Item ID column | `item_id` |
