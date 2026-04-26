# Drizzle-to-TypeBox API contracts

Use this only when the app uses Drizzle and TypeBox/Elysia route contracts.

## Select schemas

Let Drizzle define persistence shape. Derive response schemas with `drizzle-typebox`.

```ts
import { createSelectSchema } from "drizzle-typebox";
import { Static } from "elysia";
import { user } from "./schema";

export const DBUser = createSelectSchema(user);
export type DBUser = Static<typeof DBUser>;
```

Use generated schemas directly in route responses.

```ts
app.get("/users", ({ db }) => db.query.user.findMany(), {
  response: t.Array(DBUser),
  detail: { operationId: "listUsers" },
});
```

## Insert and update schemas

When body shape follows the table, derive it too.

```ts
import { createInsertSchema, createUpdateSchema } from "drizzle-typebox";

export const CreateUserBody = createInsertSchema(user);
export const UpdateUserBody = createUpdateSchema(user);
```

Override fields when API input is stricter or different from DB shape.

```ts
export const CreateUserBody = createInsertSchema(user, {
  email: t.String({ format: "email" }),
});
```

## Custom column overrides

If a DB column is JSON or otherwise too vague, override it with a route-level TypeBox schema.

```ts
export const DBJob = createSelectSchema(job, {
  metadata: t.Object({
    source: t.String(),
    retryCount: t.Number(),
  }),
});
```

## Raw variants

Use a raw variant when data must be read before it can be trusted.

```ts
export const DBJobRaw = createSelectSchema(job, {
  metadata: t.Unknown(),
});

export const DBJob = createSelectSchema(job, {
  metadata: JobMetadata,
});
```

DO NOT turn this into a standalone validator-library doctrine. This is only about keeping DB-backed API contracts close to DB tables.

## Enriched responses

Compose enriched response schemas from generated DB schema properties.

```ts
export const UserWithTeams = t.Object({
  ...DBUser.properties,
  teams: t.Array(DBTeam),
});
```

Use this for joins, computed fields, and nested data that are still returned as one API response.

## Rules

- DO NOT hand-write DB response schemas when `createSelectSchema` can derive them.
- DO NOT use generated insert/update schemas blindly if public API input differs from DB insert/update shape.
- DO NOT expose sensitive columns just because they exist in the table-derived schema.
- Prefer separate exported schema constants for reused route contracts.
