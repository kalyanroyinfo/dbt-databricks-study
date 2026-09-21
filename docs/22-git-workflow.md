# 22 — Git workflow for dbt

dbt development *is* software development: branch, commit, review, merge, deploy.

## One-time setup

```bash
uv init                 # already runs `git init`
git branch -m main      # rename master → main
git add .
git commit -m "initial commit"
```

- `git add .` **stages** everything (selects what goes into the commit).
- `git commit -m "..."` **records** the staged changes with a message.

## The everyday loop

```bash
git switch -c feature_bronze_layer   # new branch from the current HEAD
# ... build models, run dbt ...
git status                           # what changed
git add .
git commit -m "bronze layer + sources"
```

`git switch -c <name>` creates **and** checks out the branch. Everything you commit now
stays on the branch until it is merged.

Merge back:

```bash
git switch main
git merge feature_bronze_layer
```

(In a team you'd push the branch and open a **pull request** instead of merging locally —
that's where CI runs your dbt tests.)

## Connecting to GitHub

```bash
git remote -v                                            # is a remote already set?
git remote add origin https://github.com/<you>/<repo>.git
git pull origin main --allow-unrelated-histories          # only if the repo has commits (e.g. a README)
git push origin main
```

Tip: create the GitHub repo **without** a README so there is no commit to pull first.
Authenticate with a Personal Access Token (**Settings → Developer settings → Tokens**) or
the `gh` CLI.

Push a feature branch:

```bash
git push -u origin feature_bronze_layer
```

## `.gitignore` for a dbt project

```gitignore
target/
dbt_packages/
logs/
.venv/
profiles.yml        # contains a real token — never commit
.user.yml
.DS_Store
```

What **should** be committed: `models/`, `macros/`, `tests/`, `seeds/`, `snapshots/`,
`analyses/`, `dbt_project.yml`, `packages.yml`, `pyproject.toml`, `uv.lock`.

> Folders starting with `.` are hidden by default in Finder/Explorer. Show them with
> `Cmd+Shift+.` (macOS) or **View → Hidden items** (Windows).

## Commit hygiene for dbt

- One logical change per commit (`"add silver sales KPI model"`, not `"stuff"`).
- Run `dbt build` **before** committing — don't push code that doesn't compile.
- Never commit `target/` — it's generated and creates enormous, useless diffs.
- Never commit tokens. If you do, **revoke the token immediately** in Databricks; rewriting
  history is not enough, assume it's compromised.

→ Next: [23 — Deployment, targets and CI/CD](23-deployment-targets-cicd.md)
