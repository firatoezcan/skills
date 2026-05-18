---
name: frontend-a11y-interactions
description: "Accessibility and interaction quality for React UI. Use for buttons, links, dialogs, sheets, forms, tables, list rows, keyboard navigation, focus, aria attributes, and replacing fake clickable markup with semantic controls."
---

# Frontend Accessibility and Interaction Quality

Accessibility is part of correctness. It also improves code structure because semantic controls make interactions explicit.

## Semantic interaction rules

- Use `button` for actions.
- Use `a`/router links for navigation.
- Use `Dialog`, `AlertDialog`, `Sheet`, `Popover`, `Tabs`, `ToggleGroup`, and other primitives instead of custom ARIA implementations.
- DO NOT put `onClick` on non-interactive elements unless there is a documented reason and full keyboard semantics are implemented.
- List rows that open details should be `button` rows or contain an obvious button/link.
- Icon-only buttons require `aria-label` or visible sr-only text.

## Dialog and overlay rules

- Every Dialog/AlertDialog/Sheet must have a title. Use `sr-only` only when a visible title would be duplicative.
- Destructive confirmation uses `AlertDialog`, not a generic Dialog.
- Let Radix own escape handling, focus trap, and scroll lock.
- DO NOT manually add z-index stacks to compete with Radix layers.
- DO NOT mount duplicate modal content for mobile and desktop.
- Close/cancel buttons must be accessible and must not rely on pointer-only interactions.

## Form rules

- Each control has a visible label or an accessible name.
- `Field`, `FieldGroup`, `FieldSet`, `FieldLabel`, and `FieldDescription` should structure forms.
- Required/invalid/disabled state must be reflected semantically: `required`, `aria-invalid`, `disabled`, `data-invalid`, `data-disabled`.
- Placeholder text is not a label.
- Checkboxes and radios should have labels connected to the input id.
- Related checkbox/radio groups need a `FieldSet` and `FieldLegend`.

## Keyboard rules

- Anything clickable must be keyboard reachable.
- Focus states use `focus-visible` styles with semantic tokens.
- Roving/focus-managed components should come from Radix/shadcn primitives.
- Avoid trapping focus with custom fixed panels. If it is modal, use Dialog/Sheet. If it is a responsive detail pane, make sure keyboard focus is not stranded across resize.

## Tables and structured data

- Use `Table`, `TableHeader`, `TableBody`, `TableRow`, `TableHead`, and `TableCell` for tabular data.
- DO NOT fake tables with div grids when the data is genuinely tabular.
- Use `scope`/header semantics where the primitive supports it.
- Action cells should contain real controls.

## Visual feedback rules

- Hover state alone is insufficient. Include focus-visible state.
- Selected state should use `aria-current`, `aria-selected`, or data attributes as appropriate.
- Loading state should disable the initiating control and include text, not only a spinner.
- Error and destructive states should use semantic tokens/components (`text-destructive`, destructive variants, `Alert`).

## Audit commands

```sh
rg "onClick" src
rg "<div[^>]*onClick|<span[^>]*onClick" src
rg "aria-label=\"\"|DialogContent" src
rg "placeholder=" src/features src/components/chrome
```

For each match, confirm the element has the correct semantics and accessible name.
