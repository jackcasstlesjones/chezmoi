name: spec-domain-decomposition
description: >
Use this skill when the user shares a feature spec, PRD, design document, or
any structured description of a feature and asks to identify its domains,
break it down, analyse its structure, or understand what areas need to be
covered. Trigger on phrases like "what are the domains here", "break this
down", "what does this feature touch", "decompose this", or when a spec file
is shared and the user wants architectural or planning insight from it.

---

# Spec Domain Decomposition

The goal is to read a spec and identify its natural fault lines — the areas
that have their own rules, actors, data, and failure modes. Each domain, once
named, becomes a checklist item: does the spec address it, and if not, should
it?

---

## Step 1: Orient before you decompose

Answer these three questions before naming any domains:

- What is the core entity this feature is about?
- Who are the actors (people or systems that interact with it)?
- What is the feature's primary purpose? Is it a trust surface, a workflow
  tool, a content system, a social layer, a commerce system, something else?

The answers shape how much weight each domain deserves. A public profile page
and a membership management system might share structure, but they have very
different centres of gravity.

---

## Step 2: Discover domains from the spec itself

Domain-driven design's core principle is that domains are discovered, not
assigned. Rather than overlaying a fixed list onto the spec, read it and ask:
where does the language change? Where does the spec introduce a new set of
actors, rules, or concerns that couldn't be folded into what came before?

The practical signals to look for:

**Different actors with different rules** — if one section is about what an
owner can do and another is about what a member can do, those are likely
separate domains. Access control almost always has its own domain once more
than one role exists.

**State transitions** — anywhere the spec describes something moving from one
condition to another (draft to published, active to archived, pending to
approved) is a lifecycle concern. Each entity has its own lifecycle domain.

**Attribution and authorship** — if content can be created by or on behalf of
different identities, that's a domain boundary. The rules governing "who
authored this" are distinct from the rules governing what the content contains.

**External interactions** — anything the feature does that crosses a boundary
(sends a notification, triggers a payment, emits a webhook, surfaces in a feed)
represents an integration point. These are candidates for their own domain
because they have independent failure modes.

**Operational concerns separated from end-user concerns** — if the spec
distinguishes between what users see and what admins control, that separation
is a domain boundary. The admin surface has its own actors, rules, and data.

**Explicit deferrals** — anything the spec says is out of scope, coming soon,
or excluded is a domain that has been consciously parked. Name it. It tells
you where the feature is likely to grow.

Use this discovery process to build your list, then name each domain in terms
that reflect the spec's own language — not imported technical jargon.

---

## Step 3: Cross-check against known domain categories

Once you have a list from Step 2, cross-check it against these categories
drawn from established product and DDD literature. The goal is to catch
domains the spec implies but never explicitly names:

- Entity lifecycle (states, transitions, reversibility, side effects)
- Access control and permissions (roles, gates, visibility rules)
- Content and attribution (authorship, ownership, content state)
- Discovery and search (feeds, indexing, social signals)
- Notifications and events (who gets notified, through what channel)
- Settings and admin (operational controls, separated from the public surface)
- Commerce and pricing (money, legal liability, refunds)
- Progress and per-user state (tracking through a sequence)
- Verification and trust (badges, moderation, compliance status)
- Integrations and external systems (third-party connections, webhooks, APIs)
- Audit and compliance (tamper-evident history, retention, erasure)
- Performance and rendering (caching, pagination, lazy loading)
- Accessibility (semantic structure, keyboard nav, screen reader support)
- Edge cases and degraded states (empty states, missing data, status loss)

These are not universal — they are a prompt list. If a category doesn't
genuinely appear in the spec, don't force it in.

---

## Step 4: Write the breakdown

Write the output as natural prose with light headers. One paragraph per
domain, covering: what it means in the context of this specific feature,
what the interesting design decisions are, and any constraints the spec
places on it.

List deferred domains briefly at the end.

End with a short synthesis: what kind of feature this is, which domain is
doing the most structural work, and where the highest-risk design decisions
sit.

Output tone: direct, technical, collegial — like a senior dev explaining the
shape of a problem to a teammate.

```

```
