---
name: no-useless-indirection
description: "Prevent useless helper layers and pass-through wrappers. Use when adding or reviewing functions, wrappers, adapters, service helpers, utility modules, or abstractions that may only forward a call, rename another API, or pass one argument into another function without adding behavior."
---

# No Useless Indirection

Prefer the direct call when a helper only hides another helper. A function must earn its name by adding behavior, enforcing a real boundary, or making repeated code meaningfully smaller.

## Remove These

- One-parameter pass-throughs:

```ts
const getProject = (projectId: string) => backend.projects.get(projectId);
```

- Wrapper-around-wrapper query helpers:

```ts
const projectListQueryOptions = (organizationId: string) =>
  backendEden.org({ organizationId }).projects.get.queryOptions();
```

- Service/helper functions that only rename another function, preserve a legacy path, or move a single argument through another layer.
- Compatibility shims kept only so old local call sites do not need to change. This repo has no backwards-compat shims by default; update local call sites instead.

## Default Direction

- Call the real API, module function, client method, hook, command, or utility directly when the wrapper adds no policy.
- Import from the module that actually owns the capability instead of creating local synonym functions.
- If the original call is awkward, improve the owner API or the call-site shape. Do not hide the awkwardness behind a one-line alias.
- Keep names for things that carry meaning. A helper name should tell the reader about behavior, not just re-label another call.
- Prefer small, obvious duplication over an abstraction that only moves code farther away.

## Helpers Are Allowed When They Add Behavior

Create or keep a helper only when it does at least one real job:

- DTO mapping between API shapes and UI/domain shapes
- input normalization, validation, or defaulting
- mutation orchestration across multiple calls
- cache invalidation, optimistic update, or retry policy
- stream/event adaptation
- error translation with a stable user/domain contract
- a stable domain boundary shared by multiple call sites
- removing meaningful duplication that would otherwise repeat branching, mapping, or policy code

If the helper does not add one of these, inline it.

## Refactor Rule

When deleting a pass-through helper, update the local call sites in the same change. Do not leave a deprecated alias or temporary shim unless the user explicitly asks for a staged migration.
