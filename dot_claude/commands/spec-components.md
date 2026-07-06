# Component behaviour spec (component → testable .txt)

Turn one reusable component into a precise, plain-language behaviour specification that a
**non-technical tester can run end to end without ever seeing the code**. The goal is a
`.txt` that says, in ordinary words, what the tester should see, what they should do, and
exactly what must happen — so clearly that someone with no idea how the component is built
can confirm pass or fail on every line.

**You read the code; the reader of the spec never does.** Read the implementation only to
learn how the component behaves, then translate every fact into something observable. A
person testing the component cannot see a prop, a type, a file path, an attribute, or a
class name — so none of those appear in the output. They can only see what is on the screen
and do things to it. Every line of the spec must be phrased in those terms.

A great behaviour spec does five things:

1. **Orients the tester** — what the component is and where they'll find it.
2. **Lists what's on screen** — the visible parts, in plain words, with exact visible copy.
3. **Spells out every interaction** — `trigger => result`, where the result is something the
   tester can watch happen.

---

MOST IMPORTANT

- DO NOT invent or hallucinate functionality that does not exist yet
- DO NOT add loads of fluff. keep it as short as possible.

---

## Notation

Follow this exactly so every spec reads consistently and stays testable.

| Token                  | Meaning                                                                                                      | Rule                                                                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `(Entity)`             | A visible thing or actor — a part on screen, a button, a value, or the person using the component            | Capitalised noun phrase in parentheses. Use the **same name every time** for the same thing. The person interacting is always the `(User)` — the tester plays this role. |
| `[annotation]`         | A visible state or limit on the nearest thing                                                                | Lowercase inside brackets. Observable only.                                                                                                                              |
| `"quoted text"`        | Literal visible copy — labels, placeholders, messages                                                        | Quote it **verbatim** as it appears on screen.                                                                                                                           |
| `=>`                   | Separates a **trigger** (what the `(User)` does, or what happens) from its **result** (what they should see) | Trigger on the line, then `=>`, then the result on the **next line**.                                                                                                    |
| `IF … / AND … / THEN:` | A conditional behaviour                                                                                      | One clause per line; outcomes listed as `*` bullets under `THEN:`.                                                                                                       |
| `[to confirm: …]`      | A behaviour the code leaves unclear, for the user to decide                                                  | Resolve these before finishing; don't leave a tester guessing.                                                                                                           |

Common observable `[annotations]`: `[empty]`, `[disabled]`, `[greyed out]`, `[highlighted]`,
`[selected]`, `[hidden]`, `[filled in]`, `[appears on hover]`, `[up to 2 lines then "…"]`,
`[up to 100 characters]`, `[sticky at the top]`. Never use code-flavoured annotations
(types, defaults, attributes, breakpoints).

Lists and numbering:

- **Numbers** (`1.` `2.`) for the structural list of parts and for each behaviour step.
- **Decimal sub-numbers** (`2.1`) for follow-on steps and conditional variants.
- **`*` bullets** for leaf details: exact copy, the items in a list, the outcomes under THEN.
- Items typically end with `;`; the last in a group may end with `.`.

## Workflow

### 1. Learn how the component behaves

Read the component's code to understand what it does — what it renders, what reacts to a
click, what it shows while loading, and what it does on success and failure. You are doing
this only to learn behaviour; nothing about the code structure reaches the output.

Also find where the component is used in the app (check where it's imported/placed), so you
can tell the tester, in plain terms, where they'll see it — which screens or sections. The
tester must be able to locate it without help.

### 2. Translate behaviour into observable facts

Go through the component and turn every behaviour into something a person could watch:

- **On screen at rest** — every visible part, in plain words, with exact visible copy
  (button labels, placeholders) quoted verbatim.
- **Each interaction** — for everything clickable/tappable: what the tester does and the
  single visible outcome. If clicking one thing must NOT do something (e.g. a button inside
  a clickable card shouldn't open the card), say so.
- **Loading and errors** — what placeholder/spinner shows while waiting; what appears on
  success; what appears on failure, including the **exact message** and how to recover. If
  the code has no error handling, that's a `[to confirm: …]`, not an invented behaviour.
- **The edges** — what happens with the longest realistic text, a missing picture, no
  items, a slow or failed request. Describe the visible result each time.

Quote copy, labels and messages exactly. Do not paraphrase a message a tester is meant to
match against the screen.

### 3. Resolve anything unclear (ask only what the behaviour leaves open)

After reading, you'll have most of the spec. What remains is behaviour the code doesn't make
definite — what should happen on a failed action, what shows when a list is empty, whether a
disabled-looking control is meant to be inert. Collect these into one short batch and ask the
user, grouped, with multiple-choice where possible. Never ask what the running component
already shows. Anything still open stays in the spec as `[to confirm: …]`.

### 4. Write the spec to a .txt file

Write the full spec in the structure below, in the notation above. Save to
`<Component>_spec.txt` in the working directory (or a path the user specifies).

Structure:

```
<Component name>

What it is
  <one or two plain sentences: what the tester is looking at and what it's for>

Where you'll see it
  <the screens/sections of the app where it appears, in plain terms>

UI Requiements (<Component name>)
  <numbered list of the visible parts at rest; * bullets for details and exact copy>

Flow (<Component name>)
  <numbered steps: trigger => result; IF/AND/THEN for branches;
   each result is something the tester can watch happen>

```

Rules of thumb while drafting:

- Use the **same (Entity) name** everywhere for the same thing.
- Every behaviour step must have a **single, clearly observable result** — something the
  tester can look at and call right or wrong. If a step has two outcomes, split it.
- Quote all visible copy **verbatim**; never invent a label or an error message.
- Record **what the component does**, not how it's built. If the intended behaviour is
  unclear, flag `[to confirm: …]` — don't guess and don't reach for the code to explain it.
- For repeated parts, specify one fully then reference it. Don't bloat the draft.
- Keep it plain text — no Markdown headings, no bold, no tables. Blank lines between blocks
  are fine.

### 5. Present, flag what to confirm, iterate

Tell the user where the file was written. In a short note, list the **assumptions you made**
and the **`[to confirm: …]` items** still open, so the user can settle them. Then revise on
feedback. Expect 1–3 rounds.

## What to cover — checklist

Run the component through the relevant sections. Everything here is something a tester can
see; keep it that way. Where the component's behaviour is undefined, flag `[to confirm: …]`.

### Always

- **What's on screen at rest** — every visible part named, exact copy quoted.
- **Every click/tap** — each interactive thing has a step with one observable result.
- **Loading** — what placeholder/spinner shows; what replaces it on success.
- **Errors** — what shows when a request or action fails; the exact message; how to recover.
- **Empty** — what shows when there's nothing to display (no results, no items, zero count).
- **Variations** — every visibly different version and where the tester meets it.
- **Overflow** — long text: does it cut off with "…" or wrap? Try the longest realistic case.
- **Missing content** — no picture, no name, no description: what shows instead.

### Inputs and buttons

- Whether a field must be filled, and the exact message shown if the tester submits it empty.
- What a disabled-looking button does (nothing — and how the tester can tell it's inactive).
- What shows while an action is in progress, and that it can't be triggered twice.

### Search / pick-from-a-list

- What appears as the tester types; what shows while results load; what shows on **no match**.
- What happens when the tester picks a result (it fills in, or appears as a removable tag).

### Cards / tiles

- Which area opens the item, and which buttons act without opening it.
- The picture's placeholder when none is provided; what happens to a very long title.
- What each footer action visibly does.

### Navbars / menus

- What's shown when signed in vs signed out; what the current page looks like in the menu.
- On a small screen, that the menu collapses into a single button and opens/closes on tap.

### Modals / toasts

- How it opens and every way it closes (button, tapping outside).
- For a toast: how long it stays, and what happens if several appear at once.

## Quality bar — self-check before presenting

If any answer is "no", keep working:

- Could a tester who has never seen the code **find the component** from "Where you'll see it"?
- Is **every behaviour** a concrete action with **one** observable result, right-or-wrong?
- Is **all visible copy** quoted exactly as it appears?
- Are **loading, success, and error** all covered, with the exact error message?
- Is the **empty** state covered?
- Are the **variations** described by what they look like and where they appear?
- Are the **edges** (long text, missing picture, no items) written as visible outcomes?
- Is there **zero** code or jargon — no props, files, attributes, classes, or settings?
- Are **(Entity)** names consistent throughout?

## Worked example

A real, app-wide component written as a black-box behaviour spec. Match this depth.

```
Project Card

What it is
A small card summarising a single project. Clicking it opens that project's full page.

Where you'll see it
On the Projects list, in the "Related projects" row at the bottom of a project page, and in
search results.

UI Requirements (Project Card)
1. A (Cover image) across the top with:
* a (Status) tag in the top corner reading "Live", "Draft", or "Ended";
* one or more (Category) tags along the bottom edge;
2. The (Author) name and a (Timestamp) such as "3 days ago";
3. The project (Title);
4. A one-line (Tagline) beneath the title;
5. (Funding) figures: the amount raised, the goal (e.g. "of $3,500,000"), and the number of funders;
6. A bottom row of actions: a (Comment count), a (Share) button, a (Bookmark) button, and an (Open) arrow.

Flow (Project Card)
1. The (User) clicks anywhere on the card except a bottom-row action =>
The project's full page opens.
2. The (User) clicks the (Bookmark) button =>
The bookmark fills in AND the project page does NOT open.
2.1 The (User) clicks the filled (Bookmark) again =>
The bookmark empties.
3. The (User) clicks the (Share) button =>
The share option appears AND the project page does NOT open.



```
