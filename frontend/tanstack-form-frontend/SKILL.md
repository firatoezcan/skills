---
name: tanstack-form-frontend
description: "Use when adding, editing, or reviewing React forms in projects that use TanStack Form or a project-level form wrapper. Enforces typed form APIs, project field components, form subscriptions for submit state, and no local useState/raw controlled fields for submitted values."
---

# TanStack Form Frontend

## Core Rule

Every submitted frontend form should use the project's TanStack Form setup or established form wrapper. If the project has a wrapper such as `useAppForm`, use it instead of bypassing it.

Do not build submitted forms with local `useState` for field values, raw controlled `Input`/`Textarea`/`Select`, or ad hoc submit handlers that read DOM `FormData` when the project uses TanStack Form. If a UI submits user-editable fields, it belongs in the form abstraction.

Search boxes or single controls that do not submit a form can stay local state only when they are truly not forms.

## Project Pattern

- Import the project form hook, commonly `useAppForm`, from its owner module.
- Import the project `Form` primitive from the design-system layer when one exists.
- Put field values in `defaultValues`.
- Put submit behavior in `onSubmit`, using `({ value, formApi })`.
- Render the form with `Form` and call `form.handleSubmit()` from the native submit event.
- Render fields through typed field components such as `form.AppField`, using the project's field primitives: `field.Text`, `field.Password`, `field.Textarea`, `field.Select`, `field.NativeSelect`, `field.Checkbox`, or local equivalents.
- Use `form.Subscribe` for submit disabled state, pending labels, and UI that depends on current form values.
- Reset dialog forms with `form.reset()` or `formApi.reset()`, not individual field setters.

```tsx
const form = useAppForm({
  defaultValues: {
    name: "",
  },
  onSubmit: async ({ value, formApi }) => {
    await mutation.mutateAsync({ name: value.name.trim() });
    formApi.reset();
  },
});

return (
  <Form
    onSubmit={(event) => {
      event.preventDefault();
      void form.handleSubmit();
    }}
  >
    <form.AppField
      name="name"
      children={(field) => <field.Text id="name" label="Name" required />}
    />
    <form.Subscribe selector={(state) => [state.values.name, state.isSubmitting] as const}>
      {([name, isSubmitting]) => (
        <Button type="submit" disabled={isSubmitting || !name.trim()}>
          Save
        </Button>
      )}
    </form.Subscribe>
  </Form>
);
```

## Boundary Rules

- Mutation/server state can live in `useMutation`, but form field values stay in TanStack Form.
- Trim or normalize values inside `onSubmit` immediately before crossing the API boundary.
- Do not add generic value helpers such as `fieldValue`, `stringValue`, `textValue`, `numberValue`, or `asRecord`.
- If a needed field primitive does not exist in `app-form.tsx`, add a typed field component there instead of using raw controlled inputs at the call site.
- Prefer `form.AppForm` plus `form.SubmitButton` when simple submit state is enough; use `form.Subscribe` when the button also depends on current values or external mutation state.

## Review Checklist

- [ ] No `useState` for submitted field values.
- [ ] No raw controlled `Input`/`Textarea`/`Select` inside a submitted form.
- [ ] Every submitted field has a stable `name` through `form.AppField`.
- [ ] Submit button state comes from `form.Subscribe` or `form.SubmitButton`.
- [ ] Dialog close/open resets through `form.reset()` when values should clear.
