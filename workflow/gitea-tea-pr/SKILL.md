---
name: gitea-tea-pr
description: Create Gitea pull requests with the tea CLI. Use when Codex is asked to create, open, or publish a PR on a Gitea instance using tea, especially when `tea pulls create` fails on local repository discovery errors such as `worktreeconfig` or `local repository required`.
---

# Gitea Tea PR

Use this skill after the branch has been committed and pushed. It is for
creating the PR, not for deciding what code should ship.

## Workflow

1. Confirm git state:
   - `git status --short --branch`
   - `git branch --show-current`
   - `git remote --verbose`
   - `git symbolic-ref --short refs/remotes/origin/HEAD` when the base is not
     explicit.
2. Prefer the normal tea command from the repository:

```sh
tea pulls create \
  --base <base-branch> \
  --head <feature-branch> \
  --title "<clear title>" \
  --description "<markdown body>"
```

3. If `tea pulls create` fails because tea cannot parse the local repository,
   do not change git config just to satisfy tea. Common failures include:
   - `core.repositoryformatversion does not support extension: worktreeconfig`
   - `local repository required: execute from a repo dir, or specify a path with --repo`
4. Use `tea api` as the fallback. Discover the login with `tea logins`, derive
   `<owner>/<repo>` from the remote URL, and call the Gitea pulls endpoint:

```sh
tea api --login <login-name> /repos/<owner>/<repo>/pulls \
  --field base=<base-branch> \
  --field head=<feature-branch> \
  --field title="<clear title>" \
  --field body="<markdown body>"
```

The JSON response includes `html_url`; report that URL to the user.

## Guardrails

- Do not create a PR before the branch is pushed.
- Target the repository default branch unless the user names a base branch or
  the current work clearly targets a different branch.
- Keep title and body aligned with the total branch scope, not just the newest
  commit.
- Include validation results in the body when tests or checks were run.
- If Gitea reports an existing open PR for the same head branch, report the
  existing PR rather than creating duplicate branches.
- If network/auth fails, surface the exact tea error. Do not switch remotes,
  rewrite tokens, or use a different hosting service as a workaround.
