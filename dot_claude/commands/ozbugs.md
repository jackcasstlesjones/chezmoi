---
description: Pull bugs from the OZEAON Bugs Queue — by current branch's ticket, or by person name
argument-hint: [name]
---

# Pull bugs for $ARGUMENTS

## 1. Check the current branch for a ticket ID

Run `git branch --show-current` and look for `/(tozn|bozn)[-_]?\d+/i` — e.g. `tozn-327` in `feat/tozn-327-home-page-1-ui` → `TOZN-327`, or `bozn-115` → `BOZN-115`.

Load the Monday items tool either way:

```
ToolSearch select:mcp__claude_ai_monday_com__get_board_items_page
```

**If a `BOZN-###` is in the branch** → fetch that one bug directly from board `5015597434`, filtered by `item_id`. Print its full detail (title, phase, status, priority, assignees, reporter, sprint). Skip the rest of this command.

**If a `TOZN-###` is in the branch** → fetch bugs on board `5015597434` whose `bug_tasks` board-relation column links to that TOZN ticket:

```
get_board_items_page({
  boardId: 5015597434,
  filters: [{ columnId: "bug_tasks", compareValue: ["<TOZN_ITEM_ID>"], operator: "any_of" }],
  includeColumns: true,
  columnIds: ["name", "item_id", "bug_status", "color_mkynpgct", "priority_1", "people1", "multiple_person_mky2f1n9", "text_mkyjcbrw"],
  limit: 200
})
```

To get `<TOZN_ITEM_ID>` (the numeric pulse id, not the `TOZN-###` key), first query board `5015597431` with `item_id` = `TOZN-###` and grab `id` from the result. If the board-relation filter returns nothing or errors, fall back to fetching the TOZN item and reading its connected bugs from the linked column.

Jump to **Step 3** with the returned items.

**If neither** → continue to Step 2.

If Monday is not authenticated, tell the user to run `/mcp` and pick **claude.ai monday.com**.

## 2. Resolve `$ARGUMENTS` to a Monday user, fetch their bugs

If `$ARGUMENTS` is empty, default to the current user — call `list_users_and_teams({ getMe: true })`. Otherwise fuzzy-match the name:

```
ToolSearch select:mcp__claude_ai_monday_com__list_users_and_teams
list_users_and_teams({ name: "$ARGUMENTS" })
```

Pick the dev-team match. Common assignees on this board: Jack Casstles-Jones, Maxime Downe, Maria Moskvina, Yaroslav Bazhan, Roman Zagumennov, Lindomar de Sá Martins. If multiple results come back, prefer the one already seen on the Bugs Queue; otherwise ask.

Query board `5015597434` filtered by the Assigned column:

```
get_board_items_page({
  boardId: 5015597434,
  filters: [
    { columnId: "multiple_person_mky2f1n9", compareValue: ["person-<USER_ID>"], operator: "any_of" }
  ],
  includeColumns: true,
  columnIds: ["name", "item_id", "bug_status", "color_mkynpgct", "priority_1", "people1", "multiple_person_mky2f1n9", "text_mkyjcbrw"],
  limit: 200
})
```

## 3. Brief — kanban grouped by Phase

Group bugs by the `bug_status` (Phase) column in this order, skipping empty groups:

1. **Fixing** — actively being worked
2. **Ready for Dev**
3. **Backlog**
4. **Clarification**
5. Code Review
6. Deploy Queue
7. **Ready for QA**
8. **In Test**
9. **Fixed** — collapse to a count unless the user asks for the list

For each bug show: `BOZN-### — title — Priority`. Sort within a group by priority (Critical → High → Medium → Low → none).

End with a one-line takeaway: highest-priority active bug, total active count, and whether anything is stuck in Clarification.

## Reference

| Field           | Value                      |
| --------------- | -------------------------- |
| Board ID        | `5015597434`               |
| Workspace       | OZEAON Dev                 |
| Bug prefix      | `BOZN`                     |
| Reporter column | `people1`                  |
| Assignee column | `multiple_person_mky2f1n9` |
| Phase column    | `bug_status`               |
| Status column   | `color_mkynpgct`           |
| Priority column | `priority_1`               |
| Sprint column   | `text_mkyjcbrw`            |
| Item ID column  | `item_id`                  |
