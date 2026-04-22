name: decision-worksheet
description: >
Use this skill after feature decomposition has been run on a spec.
It produces a structured decision worksheet for a client or product owner
to fill in, covering all open product decisions identified in the
decomposition. Output goes to a file in ai-docs/.

---

# Decision Worksheet Generator

You have just decomposed a feature spec into its functional areas. Now
produce a worksheet that a non-technical client can fill in to make the
product decisions that unlock the build. The worksheet is a file, not a
conversation.

---

## Step 1: Identify what is already decided

Before writing any questions, read the spec and decomposition carefully
and list what is already confirmed:

- Statements of fact in the spec
- Schema or implementation choices that already enforce a behaviour
  implicitly (e.g. a cascade delete is a product decision already made)
- Items the spec explicitly marks as out of scope or deferred

Do not ask about these. State confirmed facts as preamble where helpful,
but do not present them as open questions. The client should only answer
things that are genuinely unresolved.

---

## Step 2: Derive sections from the decomposition

Do not use a hardcoded section order. Instead, read the decomposition
output and identify which feature areas contain open decisions. Each area
with open decisions becomes a section. Areas that are fully resolved, or
explicitly deferred, do not.

For each open area, ask: what format best captures the decisions here?

- If decisions vary by actor or role: use a matrix
- If decisions have a bounded set of options: use multiple-choice
  checkboxes
- If decisions are genuinely open-ended: use a short free-text field
- If an area has a sequence of states or stages with decisions at each
  step: use numbered sub-sections in chronological order

Common areas that produce sections (include only those present in this
feature's decomposition):

- Actor roles and what each can do
- Entity lifecycle (creation, approval, pending state, post-creation,
  URL/identifier changes)
- Visibility and privacy
- Verification or trust states
- Membership or participation
- Content ownership and publishing
- Deletion and what happens to dependent data
- Notifications and events

This list is a prompt, not a template. A feature may have areas outside
this list; include those too. A feature may only have two or three of
these areas with open decisions; do not force the others in.

---

## Step 3: Format rules

### Actor/role matrix

Use a matrix whenever decisions differ by role or actor. Derive the roles
from the spec or decomposition — do not assume which roles exist. Derive
the rows from the specific actions relevant to this feature — do not copy
a generic list.

State the roles as confirmed fact in the preamble before the matrix.

```

                                            ROLE-A  ROLE-B  ROLE-C

---

Action one [ ] [ ] [ ]
Action two [ ] [ ] [ ]

```

Use: Y = yes / N = no / ? = undecided (tell the client to avoid ?)

### Multiple-choice questions

Use labelled checkboxes. Always provide an Other escape hatch for
non-obvious decisions. Include a short parenthetical if the choice has
a technical implication the client may not anticipate.

```

Question text?
[ ] Option A
[ ] Option B — (note: this means X technically)
[ ] Other: _______________________________________________

```

### Notification matrix

When the feature generates events that notify actors, use a matrix.
Rows are events; columns are roles or actor types. Derive both from the
decomposition — do not use a generic event list.

```

                                    ROLE-A  ROLE-B  ROLE-C

---

Event one [ ] [ ] [ ]
Event two [ ] [ ] [ ]

```

### Free-text fields

Use sparingly. Prefer multiple choice when a bounded set of options
exists.

```

Notes: _______________________________________________

```

---

## Step 4: Lifecycle sub-sections

If the entity lifecycle area has open decisions, it often needs
sub-sections because it covers a sequence of stages. Use numbered
sub-sections (e.g. 2.1, 2.2) so the client can navigate easily.

Derive the sub-sections from the actual lifecycle stages present in
this feature. Common stages that produce sub-sections:

- Who can create the entity and how they access creation
- Any gating or approval mechanism
- The experience of any third party involved in that gate
- Failure and partial failure states within the gate
- The pending or in-progress period before resolution
- Post-creation or post-approval setup
- Identifier or URL changes after creation

Only include sub-sections that have open questions. Put them in
chronological order.

---

## Step 5: Write the file

Save the worksheet to `ai-docs/worksheet.txt`.

Open with a two-line header:

```

# [FEATURE NAME] — DECISION WORKSHEET

Fill in the answers below. Where options are given, circle or mark one.
Where a blank is given, write a short answer.
These decisions unlock the build. Nothing needs to be perfect — we can
refine later, but we need a stake in the ground for each item.

```

Close with an open notes section:

```

================================================================
ANYTHING ELSE?
================================================================
Use this space for anything not covered above, or to flag decisions
you want to discuss before committing to an answer.

Notes:

---

---

---

---

---

```

---

## Step 6: Review before saving

- No question asks about something already confirmed in the spec
- Every section has at least one real open question; remove empty sections
- All matrices derive their rows and columns from the decomposition,
  not from a generic list
- Lifecycle sub-sections are in chronological order
- Section numbers are sequential with no gaps
- The sections reflect this feature's actual open decisions, not a
  standard template applied regardless of context
