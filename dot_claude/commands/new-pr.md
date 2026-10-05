Write a PR description as plain prose paragraphs and save it to `pr-description.md` in the project root.

Write in a conversational but precise tone. No bullet points, no lists, no markdown headings in the output. No filler like "In this PR we..." or "This PR aims to..." — just start with what changed.

**Length is proportional to the diff.** Size the description to the change before you write a word of it. A one-line CSS or config fix gets one or two sentences. A focused bug fix touching a file or two gets a short paragraph. Only a branch that reshapes a subsystem earns the paragraph-per-area treatment below. Roughly: under ~20 changed lines, anything beyond a short paragraph is padding; under ~100, two or three paragraphs is the ceiling.

The example at the bottom is what a large branch looks like. It is not a template to fill in — do not reach for its shape on a five-line change.

Padding a small diff is the same failure as describing the code, and it takes the same forms: narrating the root cause at length, listing what you verified, recording what you considered and rejected, explaining a one-token change in four sentences. All of it buries the one thing the reviewer actually needs. Verification belongs in CI and in your report to the person who asked, not in the PR body. If a small fix genuinely rests on a non-obvious cause, one sentence names it.

Open with one sentence summarizing the scope of the branch. For anything larger than a focused fix, then write a paragraph per area of change (design system, navigation, cards, API, etc.), grouped by functionality not by file. Lead each paragraph with what changed, then explain how or why. Use backticks for file names, component names, prop names, and CSS classes. Mention hardcoded or placeholder content explicitly. If logic changed, say so. If it's purely cosmetic, say that too. Close by calling out what _didn't_ change if it's relevant (no API changes, no schema changes, etc.).

Don't describe every file — describe functionality and patterns. Don't oversell.

Base your description on the final diff against the target branch not on individual commits. Don't reference intermediate work that was created and then removed within the branch — the reviewer can't see it.

**The single most important rule: if the reviewer can see it by reading the diff, do not write it.** This is the most common failure mode — describing how the code works instead of why decisions were made.

Before writing any sentence, ask: does the reviewer need this to understand a decision, or would they figure it out in 30 seconds by reading the file? If the latter, cut it. This applies to everything: component wiring, data flow, standard patterns like optimistic updates, server props passed to client components, `useAsyncAction` wiring, `Promise.all` parallelisation. None of that belongs here. The description should contain things the reviewer cannot see — motivation, trade-offs, non-obvious constraints, bugs that were wrong and why.

A sentence like "`JoinOrgButton` receives `initialStatus` from the server, tracks local state with `useState`, and calls server actions via `useAsyncAction`" is exactly wrong. A sentence like "the layout was switched to the authenticated client so the button renders with correct state on first load without a client-side fetch" is exactly right. The difference: one describes the code, one explains why a choice was made that isn't obvious from reading it.

## Example output — a small fix (+3/−2, one file)

The header was a fixed `h-14` box that also carried `md:py-4`, leaving a 24px content box for 36px children. Combined with `overflow-x-hidden`, which promotes the other axis from `visible` to `auto`, that turned the header into a scroll container and painted a scrollbar right where the avatar sits. Dropped the padding and switched to `overflow-x-clip`, matching what `globals.css` already does on `body`. Clipping alone would have hidden the 12px overflow off the search field instead of removing it.

That is the whole description. No headings, no verification notes, no list of what was left alone.

## Example output — a large branch

This branch overhauls the visual layer of the app — typography, colors, component styling, and navigation — without changing how data flows or how features work.

The design system got a proper foundation. `globals.css` and `typography.css` now define semantic tokens for text colors (`text-primary`, `text-muted`, `text-placeholder`, etc.), background colors (`bg-surface`, `bg-subtle`, `bg-sunken`), and a full type scale (`text-h1` through `text-label`). Components use these tokens instead of raw Tailwind classes like `text-gray-500` or `text-sm`.

The shadcn primitives were customized to match. Button, Badge, Card, Dialog, Select, and a few others got updated — mainly sizing, border radius, and color mappings. Button now has `iconLeft` and `iconRight` props so icons are placed consistently instead of being passed as children alongside text. There's also a new `IconButton` for standalone icon-only actions like the notification bell or a close button.

Navigation was restructured. The TopNav now shows the logo, a MegaMenu trigger that displays the current page name, a search bar placeholder, and the user controls. The MegaMenu itself is a portal-rendered panel with categorized links to resources, articles, projects, media, and NFTs — the links and counts are hardcoded placeholders for now.

The SideNav was broken into smaller pieces. The old monolithic `NavMain`, `NavSecondary`, and `NavSupport` components were replaced with composable building blocks — `NavItem`, `NavCategoryItem`, `NavSectionHeading`, `NavSupportItem`. The category fetching and route matching logic is unchanged.

The RightSidebar was simplified to a static layout with upcoming events and activity stats. This is all hardcoded placeholder content.
