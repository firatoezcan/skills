---
name: repository-change-integration
description: Use this skill for non-trivial repository changes that move backend/frontend contracts, scripts, manifests, migrations, workspace tasks, runner/harness behavior, auth/session boundaries, CI, or reviewer approval surfaces.
---

# Repository Change Integration

Use this skill for non-trivial repository changes that affect contracts, scripts, manifests, migrations, workspace tasks, CI, or reviewer approval boundaries.

## Goal

Keep the repository truthful over time. Large work must leave durable repo-owned state, not only chat history.

## Session continuity

- Check `task.md` before starting or resuming a large implementation.
- Keep outstanding work in `task.md` with explicit status and current truth.
- Use a clear owner tag for the primary implementation agent when ownership needs to be recorded.
- Persist durable operating rules in repo-owned files such as `AGENTS.md`, `task.md`, or this skill before treating them as binding.

## Workflow

### 1. Contract loop

- Identify the load-bearing claim before changing code.
- Update the smallest canonical contract or entrypoint doc that defines current truth.
- Remove stale promises and unsupported capability claims.
- Keep API routes, event streams, runner protocols, auth/session behavior, migrations, and feature folder boundaries documented where the next agent will look first.

### 2. Runtime loop

- Implement the runtime path that matches the contract.
- Fix the operator/front-door path first when the main product flow is wrong.
- Prefer one canonical path over multiple half-right paths.
- Do not preserve legacy API paths, fake IDs, skipped operation objects, or pass-through wrappers unless the user explicitly asks for a staged migration.
- For Elysia work, follow the URL-shaped route layout and plugin ownership rules in `elysia-app-style`.
- For frontend work, load `frontend-react-quality` and its required stack before editing React.
- Use the repository's documented package manager and script runner. Do not switch package managers casually.
- For frontend verification, prefer the repository's canonical frontend check command. Do not substitute unrelated build, typecheck-only, or test ladders unless the user asks or the repository documents them as the canonical validation path.

### 3. Evidence loop

- Update tests, migrations, fixtures, or scripts where the contract moved.
- Add or refresh a “How to verify this” section in the relevant task/doc when the workflow is operator-facing.
- Use browser verification for UI and stream behavior that cannot be trusted from source alone.
- State what passed, what failed, and what remains intentionally out of scope.

## Harness and runner work

Agent harness changes must leave behind:

- the browser-to-backend contract
- the backend-to-runner or backend-to-harness contract
- the persistence/replay contract
- the auth/session boundary
- the local bootstrap path
- the live verification path

Browser traffic should remain authenticated through the application backend or documented auth boundary. Runners, sandboxes, and worker containers should stay private and outbound-only unless the task explicitly changes that architecture.

## Large-task rule

If the work is large enough that progress could be lost to an interruption, update `task.md` before secondary cleanup. The restart artifact is part of the implementation, not a courtesy note.

## Required outputs

For every load-bearing change, leave behind:

- updated contract or focused guidance
- runtime implementation
- verification instructions or test coverage
- reviewer-facing truth boundary
- explicit remaining work when the epic is not complete

## Rules

- Do not hide external dependencies.
- Do not return success on critical failure.
- Do not let docs outpace implementation.
- Do not let implementation outpace verification.
- Do not install new dependencies without checking first-party docs or source when the package affects auth, execution, sandboxing, or supply-chain risk.
