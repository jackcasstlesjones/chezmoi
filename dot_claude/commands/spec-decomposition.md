name: spec-decomposition
description: >
Use this skill when the user shares a feature spec, PRD, design document, or
any structured description of a feature and asks to identify its areas,
break it down, analyse its structure, or understand what needs to be covered.
Trigger on phrases like "break this down", "what does this feature touch",
"decompose this", "what areas does this cover", or when a spec file is shared
and the user wants planning or analytical insight from it.

---

# Feature Decomposition

The goal is to read a spec and identify its feature areas — the distinct
groupings of functional requirements that each have their own rules, actors,
and failure modes. Each area, once named, becomes a checklist item: does the
spec address it fully, and if not, should it?

---

## Step 1: Orient first

Before identifying any feature areas, answer these three questions:

- What is the core entity this feature is about?
- Who are the actors (the people or systems that interact with it)?
- What is the feature's primary purpose — is it a trust surface, a workflow
  tool, a content system, a social layer, a commerce system, something else?

The answers determine which areas matter most. The same questions applied to
a public profile page and a checkout flow will produce very different sets of
areas, even if some overlap.

---

## Step 2: Identify feature areas from the spec itself

Feature areas are not imported from a framework — they are read out of the
spec. Look for places where the spec introduces a new set of actors, rules,
or concerns that couldn't reasonably be folded into what came before. These
boundary signals are reliable indicators of a distinct area:

**Different actors with different rules** — if one section governs what an
owner can do and another governs what a member can do, that is an access
and permissions area. Any feature with more than one role has this.

**State transitions** — anywhere the spec describes an entity moving from
one condition to another (draft to published, pending to approved, active
to archived) is a lifecycle area. Every entity has one.

**Attribution and authorship** — if content can be created by or on behalf
of different identities, the rules governing authorship are their own area,
distinct from the content itself.

**External interactions** — anything the feature does that crosses a
boundary (sends a notification, appears in a feed, triggers a payment,
emits a webhook) has independent failure modes and belongs in its own area.

**Public surface vs. operational controls** — if the spec distinguishes
between what users see and what admins manage, that separation is a real
area boundary. The admin surface has its own actors, rules, and data.

**Explicit exclusions and deferrals** — anything the spec marks as out of
scope or coming soon is a feature area that has been consciously parked.
Name it as deferred. It tells you where the feature will grow.

---

## Step 3: Cross-check against known functional requirement categories

Once you have a list from Step 2, cross-check it against these categories
to catch areas the spec implies but never explicitly names. These are not
a universal taxonomy — they are a prompt list derived from common functional
and non-functional requirements that features regularly need to address:

Functional requirement areas commonly found in features:

- Entity lifecycle (states, transitions, reversibility, side effects)
- Access control and permissions (roles, visibility rules, permission gates)
- Content and attribution (authorship, ownership, content states)
- Membership and relationships (joining, leaving, role changes)
- Discovery and search (feeds, indexing, filters, social signals)
- Notifications and events (triggers, recipients, channels, preferences)
- Settings and admin (operational controls, separated from public surface)
- Commerce and pricing (purchase gates, refunds, payouts — isolate when
  money or legal liability is involved)
- Progress and per-user state (tracking through a sequence, junction tables)
- Verification and trust (badges, moderation states, compliance status)
- Integrations (third-party connections, webhooks, external APIs)
- Audit and compliance (tamper-evident history, retention, data erasure)

Non-functional requirement areas worth checking:

- Performance and rendering (caching, pagination, lazy loading, latency)
- Accessibility (semantic structure, keyboard nav, screen reader support)
- Edge cases and degraded states (empty states, missing data, loss of
  status, partial availability)

If a category genuinely does not appear in the spec, do not force it in.

---

## Step 4: Write the breakdown

Write the output as natural prose with light headers — one paragraph per
feature area. For each area, cover: what it means specifically in this
feature, what the interesting design decisions are, and any constraints or
rules the spec places on it.

List deferred areas briefly at the end.

Close with a short synthesis paragraph: what kind of feature this is,
which area is doing the most structural work, and where the highest-risk
design decisions sit.

Tone: direct, technical, collegial. Like a senior dev explaining the shape
of a problem to a teammate before the team starts building.
