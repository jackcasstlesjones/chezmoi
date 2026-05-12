---
name: types
description: Review TypeScript type definitions for correctness and convention violations — inline types in components, hand-rolled DB shapes, missing shared type reuse.
---

# Types Review Skill

Audit TypeScript type definitions in the files in scope. Check each rule below in order and report all violations found.

---

## Rules

### 1. No domain types defined inside component files

Types that describe data shapes (database rows, API responses, joined relations) must not be defined inside component files. They belong in a dedicated types directory.

Flag any `interface`, `type`, or inline object shape in a component file whose fields come from:

- A database table or API response
- A shared or reusable data shape
- A relation joined from another table

Wrong:

```ts
// components/ProjectCard.tsx
interface ProjectCardProps {
  project: {
    slug: string;
    title: string;
    cover_image: { path: string; alt: string | null } | null;
    author: { display_name: string } | null;
  };
}
```

Correct:

```ts
// types/projects.ts
export type ProjectCardData = ...;

// components/ProjectCard.tsx
import type { ProjectCardData } from "@/types/projects";
```

---

### 2. DB column types derived from generated types, not hand-rolled

Any field that maps directly to a database column must be typed via the generated schema types, not written as a raw primitive.

Use `Pick<GeneratedTable, "col1" | "col2">` for partial projections. Only extend with `& { ... }` for joined relations that are not raw columns.

Wrong:

```ts
export type Member = {
  id: string;
  role_id: string;
  title: string | null;
  joined_at: string | null;
};
```

Correct:

```ts
export type Member = Pick<
  Tables<"members">,
  "id" | "role_id" | "title" | "joined_at"
> & {
  role: Pick<Tables<"roles">, "id" | "name" | "slug"> | null;
};
```

---

### 3. Shared structural types used consistently

If the codebase defines a shared type for a common shape (images, addresses, money, etc.), every field with that shape must use the shared type — not an inline equivalent.

Wrong:

```ts
cover_image: { path: string; alt: string | null } | null;
logo_image: { path: string; alt?: string | null } | null;
```

Correct (assuming `Image` is the project's shared image type):

```ts
cover_image: Image | null;
logo_image: Image | null;
```

Check the shared types file(s) before writing any inline object literal for a field that could reasonably be a known shape.

---

### 4. Joined/related record shapes derived from generated types

Shapes for records joined via foreign key must derive from the generated table types, not be written as structural equivalents.

Common patterns to flag:

| Hand-rolled                                  | Should be                                         |
| -------------------------------------------- | ------------------------------------------------- |
| `{ id: string; name: string; slug: string }` | `Pick<Tables<"roles">, "id" \| "name" \| "slug">` |
| `{ id: string; label: string; url: string }` | `Pick<Tables<"links">, "id" \| "label" \| "url">` |
| `{ display_name: string }`                   | `Pick<Tables<"user_profiles">, "display_name">`   |
| `{ name: string }`                           | `Pick<Tables<"categories">, "name">`              |

---

### 5. Component prop types scoped to actual usage

A component's prop type should match exactly what the component uses — no wider, no narrower.

- If an existing domain type is a superset of what's needed, use it directly (structural typing handles it).
- If an existing domain type requires fields the component does not use AND callers cannot always supply them, define a narrower `*Data` or `*CardData` type in the types directory scoped to the component's actual needs.
- Do not widen a shared domain type just to satisfy a component — that changes the contract for all consumers.

---

### 6. Derivation hierarchy applied in order

When creating or reviewing a type, confirm the correct derivation level is used:

1. **Full row** — use the generated table type directly when all columns are needed
2. **Partial projection** — `Pick<Tables<"table">, "col1" | "col2">` for column subsets
3. **Join result** — base `Pick` extended with `& { relation: SomeType }`
4. **FK override** — `Omit<Tables<"table">, "fk_col"> & { relation: Shape }` when replacing a raw FK column with its joined shape
5. **Mutations** — use the generated insert/update types (`TablesInsert<>`, `TablesUpdate<>` or equivalent), never hand-rolled

Do not hand-roll types at a level that could be derived from the generated schema above it.

---

## Output format

List findings under a single "Type issues" heading. For each issue:

- File path and line number
- Which rule was violated
- Before/after showing the fix

If no issues are found, say so in one line. Do not report style suggestions or unrelated code quality issues.
