Analyse this repository and produce a single markdown file called CODEBASE_OVERVIEW.md in the repo root. This will be used as raw material for a client-facing case study written by someone else, so write in plain English and focus on facts, not polish.

Explore the README, docs, commit history, package manifests, CI config, tests, and the code itself. Then cover:

## What it does

Plain-English description of the product: what it does, who appears to use it, what problem it solves. No jargon.

## Key capabilities

The main things a user can do with it, described as outcomes rather than features. If there's AI functionality, describe specifically what it does, what models/services it uses, and any guardrails (human review steps, accuracy checks, how data is handled).

## Scale and evidence

Anything quantifiable: size of datasets handled, number of integrations, performance characteristics, rough timeline inferred from commit history, anything else measurable.

## Engineering quality signals

Things that suggest the project is well-built: test coverage, accessibility work (note GOV.UK design system or WCAG compliance if present), security practices, documentation, deployment setup. One line each on why it matters in practice.

## Standards and compliance

Anything relevant to public sector or regulated buyers: accessibility, data handling/GDPR, licensing, hosting.

## Unknowns

What you couldn't determine from the repo that a case study writer would want: usage stats, outcomes, client details. List as specific questions.

Rules: British English, hyphens not em dashes, no code snippets or file paths, state clearly when you're inferring rather than certain.
