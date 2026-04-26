# Controller pattern

## App shell

Keep the app entrypoint thin. It should wire global behavior and routes, not own feature logic.

```ts
import cors from "@elysiajs/cors";
import swagger from "@elysiajs/swagger";
import { Elysia } from "elysia";
import { env } from "./env";
import { routes } from "./routes";

export const app = new Elysia()
  .use(swagger({ path: "/swagger" }))
  .use(cors())
  .onError(({ code, error }) => {
    if (code === "NOT_FOUND" || code === "VALIDATION") return;
    console.error(error);
  })
  .use(routes);

if (import.meta.main) {
  app.listen({ hostname: env.HOST, port: env.PORT });
}

export type App = typeof app;
```

## Environment config

Use `env.ts` for static process configuration. Parse once at module load and import `env` directly where needed.

```ts
import { Type } from "@sinclair/typebox";
import { Value } from "@sinclair/typebox/value";

const schema = Type.Object({
  HOST: Type.String(),
  PORT: Type.Number(),
  SERVICE_NAME: Type.String(),
  SHARED_SECRET: Type.Optional(Type.String()),
});

try {
  Value.Parse(schema, process.env);
} catch (error) {
  console.error(error);
  throw new Error("Missing required environment variables");
}

export const env = Value.Parse(schema, process.env);
```

Put development defaults in `.env.local`, manifests, or test environment setup. DO NOT encode broad application defaults in helper functions.

DO NOT put this static config into request context:

```ts
// Bad
export const setup = new Elysia({ name: "setup" }).decorate("config", env);
```

Instead:

```ts
// Good
import { env } from "../env";
```

## Setup composition

For general plugin ownership rules, read `plugin-pattern.md`.

`setup.ts` is the canonical per-service plugin composition file. It should be boring: import complete plugin exports and use them.

```ts
import { Elysia } from "elysia";
import { db } from "./plugins/db";
import { auth } from "./plugins/auth";
import { logger } from "./plugins/logger";

export const setup = new Elysia({ name: "setup" }).use(auth).use(db).use(logger);
```

DO NOT add migrations, provisioning, repair jobs, or external orchestration to setup. If a feature needs expensive work, make it explicit in the feature route or a specifically named plugin.
DO NOT make setup depend on a separate activation step. A route should not work only after another module has mutated setup state.

## Controller factory

Use a factory when route modules need the same lightweight capabilities.

```ts
import { Elysia, InferContext, InputSchema, RouteSchema, Static, TSchema, t } from "elysia";
import { setup } from "./setup";
import type { RouteApp } from "./routes";

type TObject = ReturnType<typeof t.Object>;

type ConfigToContext<Config extends InputSchema | RouteSchema | undefined> =
  Config extends undefined
    ? NonNullable<unknown>
    : {
        [Key in keyof Config]-?: undefined extends Config[Key]
          ? undefined
          : Config[Key] extends TObject
            ? Static<Config[Key]>
            : Config[Key] extends TSchema
              ? Static<Config[Key]>
              : Config[Key];
      };

export type BasicContext<Config extends InputSchema | RouteSchema | undefined = undefined> = Pick<
  InferContext<RouteApp>,
  "db" | "set"
> &
  Omit<ConfigToContext<Config>, "response">;

export const createController = (name: string) => new Elysia({ name }).use(setup);
```

Adapt the picked context keys to the app. The point is to derive context from the composed app instead of hand-writing stale context types.

Keep the same controller signature:

```ts
export const createController = (name: string) => new Elysia({ name }).use(setup);
```

Route factories should be parameterless unless a parameter represents a real route variant. DO NOT pass static config, stores, clients, or broad service containers through every construction layer. That shape is plumbing noise: it forces a reader to trace call order instead of reading ownership from imports.

Use this ownership rule:

- Static process configuration lives in `env.ts` and is imported directly by the module that needs it.
- Global clients or stores live in their owner module and are imported directly, unless the app already has a real dependency-injection boundary.
- Request-derived state is exposed through setup plugins or macros.
- Route variation is represented by route modules, groups, and small explicit factory parameters only when the variation is part of the route contract.

## Route registry

Keep route registration explicit.

```ts
import { createController } from "../elysia-utils";
import users from "./users";
import userById from "./users.[userId]";

const base = createController("routes");
export type RouteApp = typeof base;

export const routes = base.use(users).use(userById);
```

## Route module

Use route files as orchestration, not as business-logic dumps.

```ts
import { t } from "elysia";
import { createController } from "../elysia-utils";
import { DBUser } from "../db/schemas";

export default createController("users").group("/users", (app) =>
  app.get(
    "/me",
    async ({ user, db }) => {
      return db.query.user.findFirst({ where: { id: user.id } });
    },
    {
      auth: true,
      response: DBUser,
      detail: { operationId: "getCurrentUser" },
    },
  ),
);
```

## Grouping

Use `.group()` for route families that share path prefixes or guards.

```ts
export default createController("projects").group("/projects/:projectId", (app) =>
  app
    .get("", getProject, {
      auth: true,
      params: t.Object({ projectId: t.String() }),
      response: DBProject,
      detail: { operationId: "getProject" },
    })
    .patch("", updateProject, {
      auth: true,
      params: t.Object({ projectId: t.String() }),
      body: UpdateProjectBody,
      response: DBProject,
      detail: { operationId: "updateProject" },
    }),
);
```
