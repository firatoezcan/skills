# Auth macro

Auth is a basic app concern. This reference covers auth-specific macro behavior. For plugin placement, setup composition, and capability ownership rules, read `plugin-pattern.md`.

## Preferred macro shape

Use an Elysia macro when authenticated routes should receive typed context such as `user`, `session`, `tenant`, or `organization`.

```ts
import { Elysia } from "elysia";

type User = {
  id: string;
  email: string;
};

type Session = {
  id: string;
  userId: string;
};

async function readSession(headers: Headers): Promise<{ user: User; session: Session } | null> {
  const authorization = headers.get("authorization");
  if (!authorization) return null;

  // Replace with the app's real auth provider/session lookup.
  return null;
}

export const auth = new Elysia({ name: "auth" }).macro({
  auth: {
    async resolve({ headers, set }) {
      const result = await readSession(headers);

      if (!result) {
        set.status = 401;
        throw new Error("Unauthorized");
      }

      return {
        user: result.user,
        session: result.session,
      };
    },
  },
});
```

Wire the auth plugin through setup:

```ts
import { Elysia } from "elysia";
import { auth } from "./plugins/auth";

export const setup = new Elysia({ name: "setup" }).use(auth);
```

If auth needs static runtime config, import `env` directly inside the auth plugin. DO NOT pass config into auth factories from app or route code.

Usage:

```ts
export default createController("account").get("/account/me", ({ user }) => user, {
  auth: true,
  response: DBUser,
  detail: { operationId: "getAccountMe" },
});
```

## Parameterized auth

Use a parameterized macro when routes need scopes or roles.

```ts
export const auth = new Elysia({ name: "auth" }).macro({
  auth: (requiredRole?: "user" | "admin") => ({
    async resolve({ headers, set }) {
      const result = await readSession(headers);

      if (!result) {
        set.status = 401;
        throw new Error("Unauthorized");
      }

      if (requiredRole && result.user.role !== requiredRole) {
        set.status = 403;
        throw new Error("Forbidden");
      }

      return { user: result.user, session: result.session };
    },
  }),
});
```

Usage:

```ts
app.get("/admin/stats", handler, {
  auth: "admin",
  response: StatsResponse,
  detail: { operationId: "getAdminStats" },
});
```

## Simple schema guard

For very small apps, a schema guard is acceptable when validation is the only need.

```ts
import { t } from "elysia";

export const apiKeyGuard = {
  headers: t.Object({
    authorization: t.String(),
  }),
};
```

Usage:

```ts
app.group("/internal", apiKeyGuard, (app) => app.get("/health", handler));
```

Prefer the macro once handlers start reading the same headers/cookies repeatedly.

## Rules

- Routes should not parse `Authorization`, cookies, or session IDs manually.
- Routes should not import auth directly when the service has a `setup.ts`; `createController(...)` should include setup.
- Auth plugins should not rely on hidden activation order or mutable setup lifecycle state.
- Routes should not repeat auth `headers` schemas unless the app is intentionally using a tiny schema guard.
- Auth should fail centrally with consistent `401` and `403` behavior.
- Auth should inject typed request state into handlers.
- Keep fake users, development defaults, and test bypasses out of the generic pattern unless the target repo already has an explicit dev-auth convention.
