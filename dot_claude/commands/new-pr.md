Write a PR description as plain prose paragraphs and save it to `pr-description.md` in the project root.

Write in a conversational but precise tone. No bullet points, no lists, no markdown headings in the output. No filler like "In this PR we..." or "This PR aims to..." — just start with what changed.

Open with one sentence summarizing the scope of the branch. Then write a paragraph per area of change (design system, navigation, cards, API, etc.), grouped by functionality not by file. Lead each paragraph with what changed, then explain how or why. Use backticks for file names, component names, prop names, and CSS classes. Mention hardcoded or placeholder content explicitly. If logic changed, say so. If it's purely cosmetic, say that too. Close by calling out what _didn't_ change if it's relevant (no API changes, no schema changes, etc.).

Don't describe every file — describe functionality and patterns. Don't oversell.

Base your description on the final diff against the target branch not on individual commits. Don't reference intermediate work that was created and then removed within the branch — the reviewer can't see it.

**The single most important rule: if the reviewer can see it by reading the diff, do not write it.** This is the most common failure mode — describing how the code works instead of why decisions were made.

Before writing any sentence, ask: does the reviewer need this to understand a decision, or would they figure it out in 30 seconds by reading the file? If the latter, cut it. This applies to everything: component wiring, data flow, standard patterns like optimistic updates, server props passed to client components, `useAsyncAction` wiring, `Promise.all` parallelisation. None of that belongs here. The description should contain things the reviewer cannot see — motivation, trade-offs, non-obvious constraints, bugs that were wrong and why.

A sentence like "`JoinOrgButton` receives `initialStatus` from the server, tracks local state with `useState`, and calls server actions via `useAsyncAction`" is exactly wrong. A sentence like "the layout was switched to the authenticated client so the button renders with correct state on first load without a client-side fetch" is exactly right. The difference: one describes the code, one explains why a choice was made that isn't obvious from reading it.

## Example output

This branch overhauls the visual layer of the app — typography, colors, component styling, and navigation — without changing how data flows or how features work.

The design system got a proper foundation. `globals.css` and `typography.css` now define semantic tokens for text colors (`text-primary`, `text-muted`, `text-placeholder`, etc.), background colors (`bg-surface`, `bg-subtle`, `bg-sunken`), and a full type scale (`text-h1` through `text-label`). Components use these tokens instead of raw Tailwind classes like `text-gray-500` or `text-sm`.

The shadcn primitives were customized to match. Button, Badge, Card, Dialog, Select, and a few others got updated — mainly sizing, border radius, and color mappings. Button now has `iconLeft` and `iconRight` props so icons are placed consistently instead of being passed as children alongside text. There's also a new `IconButton` for standalone icon-only actions like the notification bell or a close button.

Navigation was restructured. The TopNav now shows the logo, a MegaMenu trigger that displays the current page name, a search bar placeholder, and the user controls. The MegaMenu itself is a portal-rendered panel with categorized links to resources, articles, projects, media, and NFTs — the links and counts are hardcoded placeholders for now.

The SideNav was broken into smaller pieces. The old monolithic `NavMain`, `NavSecondary`, and `NavSupport` components were replaced with composable building blocks — `NavItem`, `NavCategoryItem`, `NavSectionHeading`, `NavSupportItem`. The category fetching and route matching logic is unchanged.

The RightSidebar was simplified to a static layout with upcoming events and activity stats. This is all hardcoded placeholder content.
