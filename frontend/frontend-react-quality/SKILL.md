---
name: frontend-react-quality
description: "Umbrella frontend skill for React, TypeScript, shadcn/ui, Tailwind, route, layout, dialog, responsive, state-flow, and frontend-affordance work. Load before non-trivial frontend edits or reviews so agents do not miss state locality, single-tree responsive behavior, backend-ready affordances, accessibility, routing/layout boundaries, shadcn composition, compound components, forms, or validation."
---

# Frontend React Quality System

This is the entry point for non-trivial React frontend work. Treat it as the frontend skill loader.

## Mandatory skill stack

Before editing or reviewing frontend code, read these companion skills in addition to this file when they are available:

1. `shadcn-rules`
2. `shadcn-compound-components`
3. `react-state-locality`
4. `responsive-single-tree`
5. `frontend-a11y-interactions`
6. `frontend-routing-layout-boundaries`
7. `tanstack-form-frontend`
8. `frontend-validation-pass`

Do not assume shadcn guidance alone is enough. The highest-risk frontend bugs are usually state topology, responsive duplicate trees, hidden callbacks, and incomplete backend affordances.

## Quality bar

The target is production-grade React code: local, readable state paths; predictable rendering; accessible interactions; composable APIs; and backend-ready UI contracts. A reviewer should be able to answer, from a single nearby file, what a click changes and why.

## Core invariants

### 1. State writes must be local and linear

A user interaction may update:

- local component state in the same component or nearest compound `Root`
- URL/router state for navigation or shareable filters
- a focused app-wide setting such as theme, density, sidebar state, or locale
- a server/cache mutation layer when a backend exists

A user interaction must not update a far-away parent state that is then read by an ancestor and passed into a sibling subtree. That is a non-linear data path and makes behavior difficult to trace.

### 1a. Typed data must be accessed directly

Do not add generic property/form access helpers such as `fieldValue`, `stringValue`, `textValue`, `numberValue`, `asRecord`, or equivalent wrappers. TanStack Form fields must use the typed field APIs directly. Generated/API data must be accessed through its real TypeScript types. Unknown external payloads must be typed at the boundary instead of hidden behind helper functions that erase the contract.

Submitted frontend forms should use the project's TanStack Form wrapper or established form abstraction, render fields through typed field components, and use form subscriptions for submit state. Do not use local `useState` plus raw controlled inputs for submitted form values when the project has a form framework.

### 2. Callback prop drilling is a smell

One-level callbacks for form controls and direct composition are fine. Passing `setX`, `onOpenX`, `onSelectX`, `onFullscreen`, or `onStatusChange` through wrappers or multiple component levels is not fine.

Use one of these instead:

- colocate state in the nearest compound `Root`
- make the child own purely presentational state locally
- use URL state for navigation-like state
- use an explicit dialog/action component for backend-facing operations
- extract a feature-local controller component rather than leaking callbacks across the tree

### 3. Responsive UI should be one tree

DO NOT render separate mobile and desktop content trees just because the layout changes. Prefer one detail/list/form subtree whose presentation changes through CSS, responsive classes, data attributes, and Radix primitives.

The resize test must pass: open an interaction on desktop, resize to mobile, and no stale overlay, duplicate panel, trapped focus, or orphaned state should remain.

### 4. Features must expose backend-ready affordances

Every meaningful domain action should have a visible, accessible UI affordance, even if the backend is not connected yet. Dialogs and buttons should expose stable identifiers such as `data-backend-action` and `data-backend-action-submit`, and forms should use stable `name` fields matching the intended API payload.

### 5. Routes are readable URL entry files

Routes keep `export const Route = createFileRoute(...)` at the top immediately after imports, then define route-local types/helpers and the route's Uppercase page/layout component below it. Do not make a tiny route file that only imports a one-line screen from another folder. Layout components own shell structure. Reused feature/chrome/ui components still live in their owning layer. DO NOT mix these layers just to make a route look short.

### 6. shadcn primitives own UI surfaces

Use project shadcn/ui components wherever applicable instead of custom UI. Cards, dialogs, buttons, fields, inputs, badges, alerts, separators, tabs, menus, sheets, and popovers should come from the project primitive layer, commonly `src/components/ui`, before feature code adds custom markup.

Feature JSX must not add ad hoc `rounded-*` surfaces or controls. Rounded elements belong to the design-system primitives, their variants, or established layout components. If a feature needs a new rounded visual treatment, add it to the primitive layer first.

## Work order for frontend changes

1. **Map the interaction paths.** Identify every state write introduced or touched. Verify each write is local, URL-based, global-setting-only, or server/cache-bound.
2. **Check responsive topology.** Ensure mobile and desktop render the same semantic content tree unless there is a documented, substantial IA difference.
3. **Design the component API.** Avoid 6+ props and callback chains. Use compound components when siblings share state.
4. **Make affordances backend-ready.** Add explicit dialogs/forms/actions for domain operations; avoid dead buttons and vague placeholders.
5. **Apply shadcn and token rules.** Semantic tokens, `cn()`, `gap-*`, existing primitives first.
6. **Run validation.** Use the validation skill and include what passed or could not run.

## Red flags to remove

- `useMediaQuery`, `window.innerWidth`, or JS breakpoint state controlling which tree mounts
- parent `useState` used only so a deep child can open a sibling dialog/panel
- `onClick` passed through two or more component layers
- `setSomething` props outside direct form control usage
- route files with local interaction state
- route files that only forward to a sibling screen file
- route files exporting lowercase helpers, constants, schemas, query builders, or metadata
- mobile-only Dialog plus desktop-only inline detail with duplicated children
- `useEffect` that copies one state value into another
- dead buttons, fake disabled-looking affordances, or buttons without a backend action path
- custom clickable `div`s instead of `button`, `a`, `DialogTrigger`, etc.
- submitted forms implemented with local field `useState`, raw controlled inputs, or DOM `FormData`

## Preferred Reusable Patterns

- `SplitView.Root` owns selection/search/mobile-detail visibility.
- `SplitView.Selected` and `SplitView.Filtered` read split-view context locally instead of lifting selection/filter state to feature screens.
- `DetailShell.Root` owns detail expansion locally, and the same detail subtree switches presentation by CSS.
- `ActionDialog` wraps backend-ready task modals and exposes action identifiers.
- `AppStateProvider` only owns true app-wide presentation settings.
- `routes/*` put `Route` first, colocate the route's Uppercase component, and export only `Route` plus unavoidable Uppercase React components.
