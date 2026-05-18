# Auth macro

Auth is a basic app concern. This reference covers how to expose authenticated user/session data to routes.

Prefer a dedicated auth plugin or macro module, commonly under `src/plugins/auth.ts` or `src/server/plugins/auth`. Once wired into setup, route handlers can rely on typed auth context:

```ts
export default createController("account").get("/account/me", ({ user, session }) => user, {
  auth: true, // This makes it so user and session are accessible
});
```

## Rules

- Routes should not parse `Authorization`, cookies, or session IDs manually.
- Routes should not import auth directly
