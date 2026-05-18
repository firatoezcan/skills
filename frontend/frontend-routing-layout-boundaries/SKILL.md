---
name: frontend-routing-layout-boundaries
description: "Keep TanStack route files, shell layouts, feature screens, chrome components, and UI primitives in the right layer. Use when adding screens, routes, navigation, page shells, app/workspace/admin layouts, or moving state between route/layout/feature components."
---

# Routing and Layout Boundaries

Good frontend architecture depends on layers staying narrow. A route should not become a feature controller, and a UI primitive should not know domain data.

## Layer responsibilities

### `src/routes/*`

Routes are URL-owned entry files, not tiny pass-through files:

- keep `export const Route = createFileRoute(...)` immediately after imports
- colocate the route's primary Uppercase component in the same route file instead of importing a one-line screen from a sibling feature folder
- define static route metadata such as crumbs in the `Route` object
- connect pathless layouts
- perform loader/search/beforeLoad wiring when backend/data loading is added
- move substantial reusable domain UI into features/chrome/ui only when it is actually reused or large enough to earn the jump

Routes should not be reduced to a small route file that only points at another folder. A reader should be able to open the route file and see the route definition first, then the page/layout component it renders.

Routes should not own incidental local interaction state, dialog state, list filters, fullscreen state, or feature-specific callbacks when a nearer component/compound/root owner exists. Route-level state is only for URL/search params, loaders, guards, and other real route boundaries.

Route file export rules:

- Always export `Route` at the top of the file immediately after imports. Put route-local types, helpers, and components below `Route`.
- Do not export lowercase helpers, constants, schemas, query builders, or metadata from route files.
- Prefer non-exported Uppercase route components below `Route`; if another file truly needs a route-local component, the only non-`Route` exports allowed are Uppercase React component names.
- Route files are the narrow exception where a named `function RouteComponent()` is acceptable when it is needed so `Route` can reference the component before the component body appears.

### `src/features/<surface>/<feature>/*`

Feature screens compose domain UI:

- choose data for the screen
- render page sections, list/detail shells, cards, tables, dialogs
- define feature-specific small components near the screen
- keep feature-local state only when it directly belongs to the feature component

Feature screens should not reimplement app shell, rail, topbar, or low-level shadcn primitives.

### `src/components/chrome/*`

Chrome components are app-specific reusable layout/interaction shells:

- `AppShell`, `Rail`, `TopBar`, `Page`, `PageHeader`
- `SplitView`, `DetailShell`, `ActionBar`, `DetailHead`
- `Stat`, `Sec`, `KV`, `Timeline`, `IANote`

Chrome components can own UI coordination state inside a compound boundary. They should not import feature domain data or feature screens.

### `src/components/ui/*`

UI primitives are visual/semantic building blocks:

- buttons, badges, cards, inputs, dialogs, tables, tabs, forms
- generic variants and accessibility behavior

UI primitives should not import feature code, app state, nav manifests, or seed data.

### `src/lib/*`

Shared library code:

- app-wide presentation state
- data types and seed data
- formatting helpers
- `cn()` utility

`lib` should not contain JSX-heavy feature components.

## State by layer

| Layer                 | State allowed                                                                |
| --------------------- | ---------------------------------------------------------------------------- |
| Routes                | URL/search params, loader state, route-level data boundaries.                |
| Layouts               | shell-local UI such as mobile nav drawer.                                    |
| Chrome compound roots | state for that compound API, such as split selection/search.                 |
| Feature screens       | direct feature-local UI state only when not better owned by a compound root. |
| UI primitives         | primitive-local state or Radix-controlled behavior.                          |
| App state             | true app-wide presentation settings only.                                    |

## Navigation rules

- Derive current app/surface from the route, not from a separate `app` state value.
- Navigation manifests define labels, icons, and paths; they should not own UI state.
- Command palette items navigate or open local dialogs; they should not mutate unrelated layout state.
- Breadcrumbs come from route metadata or screen-local data, not ad-hoc global state.

## Layout vs UI separation

A component should either lay out children or render a specific UI primitive, not both.

Bad shape:

```tsx
const BadgeGridCard = ({ items }) => (
  <Card className="grid grid-cols-3 gap-4">
    {items.map((item) => (
      <Badge>{item.label}</Badge>
    ))}
  </Card>
);
```

This mixes layout, card semantics, and domain rendering. Prefer a feature-level section that composes `Card`, `Sec`, or `Page` regions explicitly.

## Import direction

Allowed direction:

```txt
routes -> features -> chrome -> ui -> lib/utils
features -> lib/data, lib/format
chrome -> ui, lib/utils
ui -> lib/utils
```

Avoid reverse imports. Especially avoid:

- `components/ui` importing `features`
- `components/chrome` importing feature data
- routes importing one-line screen pass-throughs or many small leaf components instead of owning the route entry component
- `lib` importing components

## Review checklist

- [ ] `Route` is the first declaration after imports.
- [ ] Route file does not exist only to import and render a one-line screen component from another folder.
- [ ] Route file exports only `Route`, plus Uppercase React components only when truly required.
- [ ] Route file has no unnecessary `useState`/`useEffect`.
- [ ] Layout state is shell-local and not used for feature behavior.
- [ ] Feature callbacks are not drilled through layout/chrome components.
- [ ] Chrome components are domain-agnostic.
- [ ] UI primitives are app-agnostic and accessible.
- [ ] Imports follow one-way layering.
