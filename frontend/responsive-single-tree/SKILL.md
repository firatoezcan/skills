---
name: responsive-single-tree
description: "Enforce single-tree responsive React UI. Use for mobile/desktop layouts, dialogs, sheets, fullscreen/detail panels, split views, resize bugs, JS breakpoint conditionals, duplicate mobile/desktop trees, and state that must adapt gracefully across device sizes."
---

# Responsive Single-Tree UI

Responsive behavior should change presentation, not state topology. A viewport resize must not swap the app into a different interaction model with different mounted content, different state, or stale overlays.

## Non-negotiable rule

DO NOT render one stateful tree for desktop and another stateful tree for mobile when they represent the same content or task.

Bad shape:

```tsx
{
  isDesktop ? <InlineRunDetail run={run} /> : <DialogRunDetail run={run} />;
}
```

This creates two lifecycles, two focus behaviors, two close paths, and stale state when the breakpoint changes.

Good shape:

```tsx
<SplitView.Detail>
  <RunDetail run={run} />
</SplitView.Detail>
```

The detail content mounts once. CSS changes it from inline desktop pane to mobile panel.

## Use CSS and data attributes for presentation

Preferred responsive mechanisms:

- Tailwind responsive variants such as `md:*` and `max-md:*`
- `data-*` attributes set by local state
- CSS variables and semantic tokens
- Radix primitives for focus/keyboard semantics
- a single compound root that owns the state once

Example:

```tsx
<section
  data-expanded={expanded}
  className={cn(
    "flex min-h-0 flex-1 flex-col bg-background",
    "md:data-[expanded=true]:fixed md:data-[expanded=true]:inset-0",
  )}
>
  {children}
</section>
```

The `expanded` state can stay true after resizing to mobile, but it is visually scoped to desktop with `md:data-[expanded=true]:*`. No ghost desktop fullscreen remains on mobile.

## Avoid JavaScript breakpoint logic

DO NOT use these for rendering equivalent content:

- `useMediaQuery`
- `matchMedia` state
- `window.innerWidth`
- `resize` listeners that set React state
- `isMobile ? <A /> : <B />` for the same task/content

Rare exception: mobile and desktop have genuinely different information architecture, not just layout. If so, keep one canonical state machine and DO NOT duplicate the primary content body. Document the exception near the branch.

## Dialog, sheet, and detail rules

- A detail pane should have one detail subtree. Use CSS to turn it into a mobile panel.
- Fullscreen/expanded state should live inside the detail shell, not in the route or list screen.
- A mobile close button can be hidden on desktop via CSS, but it should call the same local close path.
- DO NOT have a desktop fullscreen dialog and a mobile fullscreen dialog for the same detail.
- DO NOT mount both hidden trees with `hidden md:block` and `md:hidden` if either contains interactive state.

## Resize acceptance tests

Manually or with probes, test these flows:

1. Open a detail panel on mobile, resize to desktop. The same item appears inline; no overlay remains blocking the page.
2. Expand a detail on desktop, resize to mobile. Desktop fullscreen styling stops applying; no trapped focus or fixed overlay remains.
3. Open a dialog, resize across breakpoints. The same dialog state remains valid or closes through the same primitive; no duplicate content appears.
4. Select a list row on desktop, resize to mobile. Selection remains coherent; the mobile panel open/closed state is explicit and local.
5. Close on mobile, resize to desktop. The desktop detail area should still render a sensible selected item or empty state.

## Implementation checklist

- [ ] No JS breakpoint hook controls rendering of equivalent content.
- [ ] No duplicated interactive mobile/desktop subtree for the same feature.
- [ ] State remains valid if viewport changes without firing a React event.
- [ ] Presentation-only differences are expressed with responsive classes.
- [ ] Overlay/fixed styles are breakpoint-scoped when necessary.
- [ ] Focus/escape/scroll-lock behavior comes from Radix when a true modal is used.
- [ ] Mobile close/back controls are part of the same state owner as desktop selection/detail state.

## Common fixes

| Problem                                              | Fix                                                                                                |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `isMobile` switches between inline detail and Dialog | One detail component inside `SplitView.Detail`; CSS handles panel presentation.                    |
| Route owns fullscreen item                           | `DetailShell.Root` owns `expanded`; detail content stays mounted once.                             |
| Two tab bars for mobile/desktop                      | One `Tabs` tree; style `TabsList` responsively.                                                    |
| Mobile filter drawer duplicates desktop filters      | One filter form; present as inline/overlay only if the same form subtree is reused.                |
| Resize leaves backdrop                               | Backdrop visibility comes from local state and responsive classes, not separate mobile-only mount. |
