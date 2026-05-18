---
name: shadcn-compound-components
description: "Build flexible shadcn-style compound component APIs with Root + children, private context, local state ownership, no callback drilling, and predictable responsive behavior. Use for split views, detail shells, page headers, action bars, data tables, cards, filters, and any component accumulating many props or shared sibling state."
---

# Compound Components (shadcn/ui style)

Compound components distribute responsibility across cooperating sub-components that share state through a private context. Think `<select>/<option>`: separate primitives, one coordinated unit.

Use this skill together with:

- `react-state-locality`
- `responsive-single-tree`
- `shadcn-rules`

## When to reach for it

Use a compound component when you have any of:

- many optional regions: header, toolbar, body, footer, pagination, empty state
- 6+ props on one component
- sibling coordination: selected item, filter query, expanded/collapsed state, active region
- repeated app-specific UI structure: split views, detail panes, settings sections, page headers
- callback drilling just to let a deep child update a sibling branch

DO NOT use it for simple leaf primitives such as Button, Input, Badge, or StatusDot.

## Core pattern

```tsx
"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

type PanelStateContextValue = {
  collapsed: boolean;
  toggleCollapsed: () => void;
};

const PanelStateContext = React.createContext<PanelStateContextValue | null>(null);

const usePanelState = () => {
  const ctx = React.useContext(PanelStateContext);
  if (!ctx) throw new Error("Panel.* must be used within <Panel.Root>");
  return ctx;
};

const PanelRoot = (props: React.ComponentProps<"section"> & { defaultCollapsed?: boolean }) => {
  const { defaultCollapsed = false, className, children, ...rest } = props;
  const [collapsed, setCollapsed] = React.useState(defaultCollapsed);
  const toggleCollapsed = React.useCallback(() => setCollapsed((current) => !current), []);
  const state = React.useMemo(() => ({ collapsed, toggleCollapsed }), [collapsed, toggleCollapsed]);

  return (
    <PanelStateContext.Provider value={state}>
      <section className={cn("border bg-card", className)} {...rest}>
        {children}
      </section>
    </PanelStateContext.Provider>
  );
};

const PanelTrigger = (props: React.ComponentProps<"button">) => {
  const { className, ...rest } = props;
  const { collapsed, toggleCollapsed } = usePanelState();

  return (
    <button
      type="button"
      aria-expanded={!collapsed}
      onClick={toggleCollapsed}
      className={cn("px-2", className)}
      {...rest}
    />
  );
};

const PanelContent = (props: React.ComponentProps<"div">) => {
  const { className, ...rest } = props;
  const { collapsed } = usePanelState();
  if (collapsed) return null;
  return <div className={cn("p-4", className)} {...rest} />;
};

export const Panel = {
  Root: PanelRoot,
  Trigger: PanelTrigger,
  Content: PanelContent,
};
```

## State ownership rules

- The nearest compound `Root` owns shared state for its children.
- Children read through private hooks; callers should not receive state props for internals.
- DO NOT pass raw setters out of the compound root.
- DO NOT let a child mutate state that is consumed outside the compound boundary.
- If state is needed outside the boundary, ask whether it is really URL state, server/cache state, or an app-wide setting.
- Avoid `useEffect` for state sync. Derive selected/filtered items from ids/query with `useMemo` or render helpers.

## Split contexts by concern

One giant context makes every child re-render and hides which concern is changing. Split by update frequency and mental model.

Good:

```tsx
const SelectionContext = React.createContext<SelectionValue | null>(null);
const SearchContext = React.createContext<SearchValue | null>(null);
```

Bad:

```tsx
const EverythingContext = React.createContext({
  selectedId,
  setSelectedId,
  query,
  setQuery,
  density,
  appMode,
  drawerOpen,
  setDrawerOpen,
});
```

A compound context should feel like the API of one component, not a feature-wide store.

## Render-prop readers for local data paths

When a feature needs filtered or selected data, prefer a compound reader so parent screens DO NOT lift the state:

```tsx
<SplitView.Root initialSelectedId={runs[0]?.id}>
  <SplitView.List>
    <SplitView.Search placeholder="Search runs…" />
    <SplitView.Filtered items={runs}>
      {(filtered) => filtered.map((run) => <RunRow key={run.id} run={run} />)}
    </SplitView.Filtered>
  </SplitView.List>
  <SplitView.Detail>
    <SplitView.Selected items={runs}>
      {(run) => (run ? <RunDetail run={run} /> : <SplitView.DetailEmpty />)}
    </SplitView.Selected>
  </SplitView.Detail>
</SplitView.Root>
```

The screen composes the feature. The split view owns its interaction state. No parent callback chain is required.

## Responsive compound components

A compound root is often the right owner for responsive interaction state, but it should not branch into separate stateful trees. Use data attributes and CSS variants:

```tsx
<div
  data-open={detailOpen}
  className={cn(
    "relative flex min-h-0 flex-col",
    "max-md:fixed max-md:inset-0 max-md:data-[open=true]:translate-x-0",
  )}
>
  {children}
</div>
```

The children stay mounted once; only presentation changes.

## Rules

### Do

- Root owns all shared state via `useState` / `useMemo` / private context.
- Use one context per concern when concerns update independently.
- Memoize context values that contain state/callbacks.
- Use arrow functions and body prop destructuring.
- Forward unknown props to the underlying DOM element.
- Throw a clear error when a child is used outside Root.
- Export as a namespace object: `export const Thing = { Root, Header, ... }`.
- Use shadcn primitives inside compound children when appropriate.
- Keep children dumb: read context, emit markup, forward props, use `cn()`.
- Set `displayName` for debuggability.

### DO NOT

- DO NOT create a 20-prop component.
- DO NOT prop-drill state/callbacks between siblings.
- DO NOT expose setters as part of the public API unless the component is explicitly controlled.
- DO NOT put app-wide or feature-wide domain state in a chrome compound context.
- DO NOT define spacing/colors independently in every child.
- DO NOT use `useEffect` to mirror Root state into child state.
- DO NOT render separate interactive mobile and desktop branches inside the compound.
- DO NOT reinvent shadcn primitives.

## Controlled vs uncontrolled

Default to uncontrolled local state inside the Root. Add a controlled API only when there is a real external owner such as URL state or server cache.

If adding controlled props, use the standard pattern:

```tsx
type RootProps = {
  value?: string;
  defaultValue?: string;
  onValueChange?: (value: string) => void;
};
```

DO NOT half-control a component by accepting `selectedId` but keeping hidden internal copies that can diverge.

## Checklist before exporting

- [ ] Root owns the shared state, not a far-away parent.
- [ ] Children consume context; no drilled internal state props.
- [ ] Context hook throws outside Root.
- [ ] Context is split by concern if needed.
- [ ] Context values are memoized.
- [ ] Public callbacks are semantic and necessary, not raw setters.
- [ ] Conditional classes use `cn()`.
- [ ] No `space-x-*`, `space-y-*`, `dark:*`, or raw colors.
- [ ] Unknown props are forwarded.
- [ ] Responsive behavior keeps one content tree.
- [ ] `displayName` is set.
- [ ] Namespace export documents the API.
