# Skills

Reusable Codex skills grouped by purpose.

This repository owns general methods. Product repositories own their domain
rules, release authority, account policy, runtime configuration, and agent
topology. A product may vendor one of these skills and add local constraints,
but changes do not flow between repositories automatically. Review both copies
and keep the general method here free of product names and private operations.

## Structure

- `architecture/`: code quality, architecture, and cross-repository change guidance
- `backend/`: backend and Elysia API guidance
- `browser/`: browser automation
- `frontend/`: React, shadcn/ui, accessibility, responsive UI, and forms
- `principles/`: small decision rules that apply across languages and products
- `research/`: repository-first and primary-source research
- `router/`: TanStack Router core and sub-skills
- `workflow/`: planning, isolated work, commit, push, and PR landing workflows
- `writing/`: human agent communication and technical prose

## Import boundary

Import a skill only when its full workflow is portable. Do not copy a
product-specific deployment flow, secret location, account identifier, issue
tracker policy, simulation persona, model-routing table, or editor runtime
configuration into this repository. Keep a specialized skill in its owning
product repository when removing that context would make it misleading.

Avoid two general skills with the same name or purpose. Update the existing
owner instead of adding a newer copy under another category.
