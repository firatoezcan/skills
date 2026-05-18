---
name: shadcn-rules
description: "Enforce shadcn/ui code style and composition rules: semantic tokens, gap over space, cn() conditionals, existing primitives first, forms with field components, accessible overlays, and no raw Tailwind color hacks. Use whenever writing or reviewing shadcn/Tailwind/Radix React code."
---

# shadcn/ui Rules

These are conventions for shadcn/Tailwind/Radix code. Also read the umbrella `frontend-react-quality` skill first when it is available.

## Principles

1. **Use existing components first.** Check `src/components/ui` and shadcn/Radix primitives before adding custom markup.
2. **Compose, DO NOT reinvent.** Settings = Tabs + Card + Field. Dashboard = Page + Sec + Card/Table/Stat. Actions = Button + Dialog/AlertDialog.
3. **Prefer built-in variants.** Use `variant="outline"`, `variant="destructive"`, `size="sm"`, etc. Add a new variant only when the pattern repeats.
4. **Semantic tokens only.** Use `bg-card`, `text-muted-foreground`, `text-ok`, `text-destructive`, `border-line-soft`. DO NOT use raw color utilities or hex values in components.
5. **Layout remains explicit.** Use `gap-*`, grid/flex, and round spacing steps. Avoid one-off values unless they are encoded as CSS variables.
6. **Design-system radius only.** Do not add ad hoc `rounded-*` classes in feature JSX. Use shadcn/ui components and their variants for rounded surfaces and controls. If a primitive cannot cover the case, add the radius behavior to the design-system component instead of the feature.

## Styling rules

- **`cn()` for every conditional class.** No template-literal ternaries for class names.
- **No `dark:` classes.** Theme is handled by semantic tokens and CSS variables.
- **No `space-x-*` / `space-y-*`.** Use `flex flex-col gap-*` or `flex items-center gap-*`.
- **No feature-local rounded surfaces.** `rounded-*` belongs inside design-system primitives, variants, or layout components, not one-off feature markup.
- **Use `size-*` when width equals height.** `size-10`, not `w-10 h-10`.
- **Use `truncate`.** DO NOT spell out `overflow-hidden text-ellipsis whitespace-nowrap`.
- **No manual z-index wars.** Dialog/Sheet/Popover/Tooltip handle layers. Only shell-level constructs such as a responsive detail pane may use scoped z-index, and it must be justified by the component boundary.
- **No raw gradients, hex colors, or status color hand-picking in JSX.** Add semantic CSS variables in `globals.css` when a token is missing.

## Status and operational color

Never reach for raw Tailwind status colors:

```tsx
// Wrong
<span className="text-emerald-600">healthy</span>
<span className="bg-red-100 text-red-900">failed</span>

// Right
<Badge variant="secondary">healthy</Badge>
<span className="text-destructive">failed</span>
<StatusBadge status="failed" />
```

If the product needs an operational token such as success/warning/info, define it once in CSS and consume it semantically (`text-ok`, `text-warn`, etc.).

## Forms

- Use `FieldGroup` + `Field` for form layout.
- Use `FieldSet` + `FieldLegend` for checkbox/radio groups.
- Use `FieldLabel`, `FieldDescription`, and `FieldError`/invalid patterns when validation exists.
- Every control must have a stable `name` when it maps to a backend payload.
- Use `data-invalid` on `Field`, `aria-invalid` on controls.
- Use `data-disabled` on `Field`, `disabled` on controls.
- Placeholder text is not a label.
- DO NOT create local React state for every input unless typing immediately changes visible UI. Static mock forms should generally use `defaultValue` and backend-ready names.

## Composition rules

- **Items inside groups:** `SelectItem` → `SelectGroup`, `DropdownMenuItem` → `DropdownMenuGroup`, `CommandItem` → `CommandGroup`.
- **Dialog/Sheet/AlertDialog always need a title.** Use `sr-only` only when the visible title is intentionally elsewhere.
- **Use full Card composition.** `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`.
- **Button has no custom `isLoading` / `isPending` prop.** Compose loading state: `<Button disabled><Spinner data-icon="inline-start" /> Saving…</Button>`.
- **`TabsTrigger` belongs inside `TabsList`.** Never render triggers directly under `Tabs`.
- **`Avatar` needs `AvatarFallback`.** Images can fail.
- **No giant prop surfaces.** If a component wants 6+ props, consider a compound component API.

## Use components, not custom markup

Use project shadcn/ui components wherever they apply. Custom JSX containers are acceptable only for layout that no existing primitive owns.

| Instead of                | Use                                                      |
| ------------------------- | -------------------------------------------------------- |
| `<hr>` / border div       | `Separator`                                              |
| pulse div skeletons       | `Skeleton` when available                                |
| custom status pill        | `Badge`, `StatusBadge`, `StatusDot`, `Pill`              |
| custom callout div        | `Alert`                                                  |
| custom empty state        | `Empty`                                                  |
| hand-rolled confirm modal | `AlertDialog`                                            |
| fake clickable row div    | `button`, `a`, or a primitive trigger                    |
| console/alert placeholder | backend-ready `ActionDialog` or `toast()` when installed |

## Icons

- In `Button`, pass icons as children with `data-icon` only when the primitive expects it.
- DO NOT manually size icons inside Button/Badge/Alert when the component already handles sizing.
- Pass icon components/objects, not string lookup keys.
- Icon-only controls need `aria-label`.

## Choosing overlays

| Use case                                 | Component                                      |
| ---------------------------------------- | ---------------------------------------------- |
| Focused task with input                  | `Dialog` / `ActionDialog`                      |
| Destructive confirmation                 | `AlertDialog`                                  |
| Side panel for auxiliary details/filters | `Sheet`                                        |
| True mobile bottom interaction           | `Drawer` if installed and appropriate          |
| Hover info                               | `HoverCard`                                    |
| Small click-triggered content            | `Popover`                                      |
| Inline/mobile list detail                | `SplitView.Detail`, not duplicate Dialog trees |

## Customization order

1. Built-in variants.
2. Semantic token classes.
3. CSS variables in `globals.css`.
4. New variant via `cva` inside the component source.
5. Wrapper/compound component that composes primitives.

DO NOT jump straight to one-off classes or raw colors.

## React Rules

- Arrow functions for React components, except route files may use a named `function RouteComponent()` when needed so `Route` stays at the top.
- Destructure props inside the body, not in the signature.
- No `useEffect` for state-to-state sync. Derive values or set them in the event handler.
- No heavy prop drilling. Use compound component context or route/server state depending on the concern.
- No duplicate mobile/desktop interactive trees. See `responsive-single-tree` when available.
- Keep routes as readable URL entry files with `Route` first and the Uppercase route component colocated. See `frontend-routing-layout-boundaries` when available.

## Quick review checks

```sh
rg "dark:" src || true
rg "space-[xy]-" src || true
rg "#[0-9a-fA-F]{3,8}" src || true
rg "bg-(red|blue|green|yellow|purple|pink|indigo|emerald|amber|slate|zinc|stone|gray)-|text-(red|blue|green|yellow|purple|pink|indigo|emerald|amber|slate|zinc|stone|gray)-" src || true
rg "^function [A-Z]|function [A-Z].*\(" src || true
rg "<div[^>]*onClick|<span[^>]*onClick" src || true
```
