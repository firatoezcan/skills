---
name: frontend-validation-pass
description: "Validation checklist for frontend changes. Use at the end of any React/shadcn/Tailwind/state/responsive work to run the repository's canonical frontend verification command and review common UI quality queues."
---

# Frontend Validation Pass

Every frontend change should end with the repository's canonical frontend validation command.

## Primary validation

Run the documented frontend check from the repository root. Prefer the command named in `README`, `AGENTS.md`, package scripts, or local task docs.

```sh
# Examples only; choose the current repository's canonical command.
pnpm check
pnpm lint
pnpm test
```

Do not replace the canonical check with an unrelated build, typecheck-only command, test ladder, or custom parse check. Run broader validation when the user asks, the repository documents it, or the risk of the change clearly requires it.

## Required grep checks

Run from the repository root. These checks are review queues, not a substitute for the canonical validation command, and they do not authorize unrelated build, test, or typecheck verification.

```sh
# shadcn/style rules
rg "dark:" src || true
rg "space-[xy]-" src || true
rg "bg-(red|blue|green|yellow|purple|pink|indigo|emerald|amber|slate|zinc|stone|gray)-|text-(red|blue|green|yellow|purple|pink|indigo|emerald|amber|slate|zinc|stone|gray)-" src || true
rg "#[0-9a-fA-F]{3,8}" src || true

# React/component rules
rg "^function [A-Z]|function [A-Z].*\(" src || true
rg "console\." src || true
rg "useEffect" src || true

# State locality and callback drilling
rg "set[A-Z][A-Za-z0-9_]*=" src || true
rg "on[A-Z][A-Za-z0-9_]*=" src/features src/components/chrome || true
rg "useMediaQuery|matchMedia|innerWidth|resize" src || true

# Accessibility and fake interactions
rg "<div[^>]*onClick|<span[^>]*onClick" src || true
rg "<a(\s|>)(?![^>]*href)" src || true
rg "DialogContent" src || true
```

These greps are review queues, not hard failures. Adjust paths if the frontend source does not live under `src`. For every match, decide whether it is acceptable and document notable exceptions.

If the canonical check fails because dependencies, credentials, services, network access, or environment setup are missing, report the exact command and failure. Do not substitute a different validation ladder without saying why.

## State path review

For every new or touched `useState`/context:

- [ ] Is the state owner the nearest sensible owner?
- [ ] Does a write update only descendants or the same component?
- [ ] Is any callback drilled more than one layer?
- [ ] Would the UI remain coherent after resizing?
- [ ] Could this be derived instead of stored?
- [ ] Is it actually route/server/app setting state?

## Responsive review

- [ ] No JS breakpoint controls equivalent content rendering.
- [ ] Mobile and desktop share one semantic content tree.
- [ ] Fixed/overlay styles are breakpoint-scoped.
- [ ] Open/close state adapts across resize.
- [ ] Focus does not get trapped in a hidden/offscreen duplicate.

## Backend-affordance review

- [ ] Every visible domain verb has an affordance.
- [ ] Every backend-ready dialog has a stable action id.
- [ ] Every form field has a stable `name` and accessible label.
- [ ] Destructive actions use confirmation.
- [ ] No dead `onClick`, `console.log`, or fake submit placeholders remain.

## Final report format

Include:

- what changed
- key state-path/responsive decisions
- whether the canonical frontend validation passed or failed
- any remaining limitations or intentional exceptions
