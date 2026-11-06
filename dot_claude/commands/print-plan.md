---
description: Write the current plan to PLAN.md so someone who has read nothing else can follow it and answer its questions. Covers the questions to decide, findings, acceptance criteria and step-by-step implementation.
---

# Print plan

Write the plan we've been discussing to a markdown file the user can read outside this conversation.

The file is `PLAN.md` in the repo root, unless `$ARGUMENTS` names another path. If it already exists, read it first: update it if it's this plan, and ask before overwriting a different one. Don't commit it unless asked.

**The test for every line: could someone who has read only this file understand it and act on it?** Nothing may depend on this conversation, the ticket, or having seen the code.

## Before writing

- Read the ticket and its comments, and any open PR this work builds on, including its description and review comments. Reading the branch's code is not the same as reading the PR
- Check anything the plan asserts about the code or the system by running it or reading it. If you couldn't check something, say so in the plan

## Structure

Use these sections, in this order. Leave out a section only if it would be empty.

### 1. Title and status

The ticket or feature name, the branch and what it builds on, then one bold line saying what the plan is waiting on, such as `**Status: waiting on the 5 questions below.**`

### 2. What this does

Two or three plain sentences: what's wrong today, what changes, and who notices. Follow with **Terms used below**, a short list defining each term the questions rely on. Include anything a smart reader outside the project wouldn't know.

### 3. Questions

One table, with a row per question, numbered `Q1`, `Q2` and so on.

| # | Background and question | Option A (recommended) | Option B | Option C |
| --- | --- | --- | --- | --- |
| Q1 | **The question in bold.** What the thing is, what we found, and why it needs deciding. | **The choice in bold.** What you gain and what it costs. | ... | `n/a` if unused |

- Every question stands alone: no bare ticket codes, tool names or "see finding 3" in place of an explanation
- Include concrete numbers from what you found
- Put the recommended option in column A, and give every option its real cost, including the recommended one
- Only ask what you can't settle yourself from the code, the ticket or sensible defaults

Above the table, say how to answer, such as "Reply with 'go with A', or 'A except Q2 B'".

### 4. Findings

A section with exactly this heading, numbered `1.`, `2.` and so on: facts that shaped the plan and would surprise the reader. Each starts with the finding in bold, then its evidence (real numbers, the file, the command result) and what it means for the work. Leave out anything already obvious from the ticket.

### 5. Acceptance criteria

A table with `AC1`, `AC2` and so on, and the columns `AC`, `Criterion`, `Method` and `Expected result`. Method says how it will be proved (a named test, a command, a browser check). If a criterion can't be proved yet, say what it's waiting on and who does it.

### 6. Step-by-step implementation

Numbered steps, grouped under `### Stage N: <what it achieves>`, numbered continuously across stages so each step has one number.

- Each step is one action, with the full path of any file it touches
- Tag a step that depends on an answer with **(Q1)**, and reference **(AC1)** or (finding 2) where one explains the step
- Mark steps the user has to run themselves with **You run**: anything they've said they want to run, and anything long-running or touching a production machine
- Include proving each criterion, and finish with what happens after merge, if anything does

### 7. Files

The files to create or change, grouped by area, with full paths from the repo root.

### 8. Left out

What's deliberately not included, each with its reason.

## Writing rules

- Plain, direct English. Explain a term or avoid it
- Every reference must resolve: if a step says (Q3) or (finding 2), that item exists under that exact heading
- Use one word for one thing throughout
- Keep table cells to a sentence or two of background and option text, moving longer explanation into Findings
- State only what's true now. When things change, update the status line and any facts they affect

## After writing

Reply with the file's full path, what the plan is waiting on, and your recommendation. Don't repeat the plan in the reply.
