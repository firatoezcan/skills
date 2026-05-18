---
name: react-state-locality
description: "Prevent non-linear React data paths, hidden callback drilling, far-away state writes, over-broad contexts, and useEffect state synchronization. Use whenever adding state, callbacks, context, dialogs, filters, list/detail selection, fullscreen/detail expansion, or reviewing code that feels hard to trace."
---

# React State Locality and Linear Data Paths

React code is readable when a state write and its visible consequence are near each other. The goal is not “no context” or “no lifted state”; the goal is a linear, inspectable path.

## Definitions

### Linear data path

A write is linear when the changed value is consumed in the same component, a direct child, or descendants of the nearest obvious owner.

Good examples:

- `DetailShell.Root` owns `expanded`; `DetailShell.ExpandButton` toggles it; the shell itself consumes it through `data-expanded`.
- `SplitView.Root` owns selected row and search query; `SplitView.Row`, `SplitView.Search`, `SplitView.Selected`, and `SplitView.Filtered` consume that state inside the compound component boundary.
- A local dialog component owns `open` or delegates open state to Radix internally.
- `useAppState` changes theme/density/commentary because those are explicit app-wide presentation settings.

### Non-linear data path

A write is non-linear when a deep interaction mutates state in a far-away component, which then rerenders an ancestor or sibling branch.

Bad shape:

```tsx
const RunsScreen = () => {
  const [fullscreenRun, setFullscreenRun] = React.useState<Run | null>(null);

  return (
    <SplitView.Root>
      <SplitView.List>{/* ... */}</SplitView.List>
      <RunDetail onFullscreen={() => setFullscreenRun(run)} />
      {fullscreenRun && <Fullscreen run={fullscreenRun} />}
    </SplitView.Root>
  );
};
```

The click lives inside `RunDetail`, the state lives in `RunsScreen`, and the visual consequence is a sibling overlay. That is hard to trace and fragile across responsive changes.

Good shape:

```tsx
const RunDetail = (props: { run: Run }) => {
  const { run } = props;

  return (
    <DetailShell.Root>
      <DetailHead.Root>
        <DetailShell.ExpandButton />
      </DetailHead.Root>
      {/* one detail subtree */}
    </DetailShell.Root>
  );
};
```

## State placement decision table

| State kind                                    | Preferred owner                                  | Notes                                                           |
| --------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Theme, density, commentary                    | `AppStateProvider`                               | True app-wide presentation settings only.                       |
| Route, selected workspace, active app section | Router / URL / nav manifest                      | Derive from location; DO NOT store duplicate app mode.          |
| List/detail selection                         | Nearest list/detail compound root                | Use `SplitView.Root`, `Selected`, `Filtered`, rows.             |
| Dialog open state                             | Radix uncontrolled state or local dialog wrapper | Avoid route-level `dialogOpen` unless URL-addressable.          |
| Fullscreen/detail expansion                   | The detail shell itself                          | Use one subtree and CSS-scoped expansion.                       |
| Form draft values                             | Form element / local form component              | Use `defaultValue`, stable `name`, then backend mutation later. |
| Server data and mutations                     | Query/cache layer when added                     | DO NOT simulate server cache with broad app context.            |
| Shared UI config for a component family       | Compound root context                            | Keep context private to the component namespace.                |

## Callback rules

### Allowed

- Direct control callbacks: `<Input onChange={...} />` in the same form component.
- One-hop semantic callbacks when parent and child are one abstraction: `<Dialog onOpenChange={...} />`.
- Backend action handlers at the boundary that actually submits/mutates.
- Event handlers passed into shadcn/Radix primitives as part of the primitive API.

### Not allowed

- Passing raw setters as props: `setOpen`, `setSelectedId`, `setStatusFilter`, `setFullscreenItem`.
- Passing callbacks through presentational wrappers that DO NOT own the state.
- A child button whose click changes a sibling branch through parent state.
- “Callback bundles” like `actions={{ open, close, select, promote }}` unless they are a feature-local controller with a documented boundary.
- Parent state used only because two siblings need it; prefer a compound root surrounding both siblings.

## Context rules

Context is not a dumping ground. Use context when:

- the state is scoped to a visible component boundary
- descendants need to coordinate
- the provider and consumers can be inspected together

DO NOT use context when:

- only one child needs a value
- the state is actually route state
- the value is domain data that should come from the server/cache layer
- providers are stacked at the root just to avoid props
- a write in one feature changes behavior in another unrelated feature

For performance and clarity, split contexts by concern and update frequency:

```tsx
type SelectionContextValue = {
  selectedId: string | null;
  openDetail: (id: string) => void;
};

type SearchContextValue = {
  query: string;
  setQuery: (query: string) => void;
};
```

Selection and search are different concerns; separate contexts make updates and readers easier to understand.

## Avoid state synchronization effects

Never use `useEffect` to copy state into state:

```tsx
// Wrong
React.useEffect(() => {
  setActiveItem(items.find((item) => item.id === selectedId));
}, [items, selectedId]);
```

Derive it instead:

```tsx
const activeItem = React.useMemo(
  () => items.find((item) => item.id === selectedId) ?? null,
  [items, selectedId],
);
```

Effects are for external systems. They are not for keeping React state in sync with other React state.

## Audit procedure

When reviewing a file or feature, search for these patterns:

```sh
rg "useState|useReducer|useContext|createContext" src/features src/components/chrome src/routes
rg "set[A-Z][A-Za-z0-9_]*=" src
rg "on[A-Z][A-Za-z0-9_]*=" src/features src/components/chrome
rg "useEffect" src
```

For each state write, answer:

1. Where does the value live?
2. What event writes it?
3. Which components read it?
4. Is the closest owner obvious at the call site?
5. Would resizing or route changes leave stale UI behind?

If the answer is not obvious, move the state to a nearer owner, derive it, or express it in the URL/server cache.

## Refactor playbook

- **Deep child opens far-away overlay:** move overlay state into the child’s local shell or use a compound root around both trigger and panel.
- **Parent filters list and passes filtered data plus setter:** put query/filter state in the list compound root and expose a render prop like `Filtered`.
- **Parent selects item and passes selected object into detail sibling:** keep selected id in the split root; expose `Selected` inside detail.
- **Route owns UI tab state:** use shadcn `Tabs` locally or URL search params if shareable.
- **App context contains feature UI state:** remove it; only true global presentation settings belong there.
