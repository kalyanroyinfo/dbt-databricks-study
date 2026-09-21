# 21 — dbt command cheat sheet

> **Every dbt command must be run from inside the project folder** (the one containing
> `dbt_project.yml`). Here: `cd dbt_databricks_src`.
> Otherwise: `Could not find dbt_project.yml`.

## Setup / environment

| Command | Purpose |
| --- | --- |
| `uv init` | start the Python project (also runs `git init`) |
| `uv sync` | create `.venv` from `.python-version` + install deps |
| `uv add dbt-core dbt-databricks` | install dbt + adapter |
| `uv add -r requirements.txt` | install from a requirements file |
| `uv pip freeze > requirements.txt` | export pinned deps |
| `uv remove <pkg>` | uninstall |
| `dbt --version` | dbt core + adapter versions |
| `dbt` | list all commands (also a quick install check) |

## Project lifecycle

| Command | Purpose |
| --- | --- |
| `dbt init` | scaffold a new project + write `profiles.yml` |
| `dbt debug` | validate config, profile and connection — **run this first when stuck** |
| `dbt deps` | install packages from `packages.yml` |
| `dbt clean` | delete `target/` and `dbt_packages/` |
| `dbt parse` | parse the project without hitting the warehouse |

## Building

| Command | Purpose |
| --- | --- |
| `dbt run` | build **models** only |
| `dbt seed` | load **seeds** (CSVs) |
| `dbt snapshot` | run **snapshots** (SCD2) |
| `dbt test` | run **tests** only |
| `dbt build` | **seeds → models → snapshots → tests**, in DAG order ⭐ |
| `dbt compile` | render Jinja → SQL into `target/compiled/`, no execution |
| `dbt show --select m` | preview rows from a model |
| `dbt run --full-refresh` | rebuild incrementals/snapshots from scratch |
| `dbt retry` | rerun only what failed last time |

**`dbt build` is the one to remember** — it's what orchestrators and CI/CD pipelines call,
because it respects dependencies *and* stops a branch when its tests fail.

## Selection (works on run/build/test/seed/snapshot/ls/compile)

| Command | Purpose |
| --- | --- |
| `dbt run --select my_model` | one model |
| `dbt run --select "a b"` | several |
| `dbt run --select models/bronze` | a folder |
| `dbt build --select +my_model` | model + upstream |
| `dbt build --select my_model+` | model + downstream |
| `dbt run --select tag:daily` | by tag |
| `dbt run --exclude bronze_date` | everything except |
| `dbt ls --select my_model+` | list what would be selected |

## Environments

| Command | Purpose |
| --- | --- |
| `dbt build --target prod` | run against the `prod` output in `profiles.yml` |
| `dbt run --vars '{key: value}'` | pass project variables |
| `dbt run --profiles-dir ./` | use a `profiles.yml` from a specific folder |

## Docs

| Command | Purpose |
| --- | --- |
| `dbt docs generate` | build the docs site + `manifest.json` |
| `dbt docs serve` | serve it locally with the DAG viewer |
| `dbt source freshness` | check whether raw data is stale |
| `dbt run-operation my_macro --args '{a: 1}'` | run a macro standalone |

## Typical day

```bash
cd dbt_databricks_src

dbt debug                         # 1. connection healthy?
dbt build --select bronze_sales+  # 2. build what I changed + downstream
dbt test --select bronze_sales    # 3. check quality
dbt clean                         # 4. tidy generated files

git add . && git commit -m "bronze layer"
```

## Handy flags

| Flag | Effect |
| --- | --- |
| `--full-refresh` | ignore incremental state, rebuild |
| `--fail-fast` / `-x` | stop at the first failure |
| `--threads 4` | override profile threads |
| `--debug` | verbose logging |
| `--warn-error` | treat warnings as errors (great for CI) |
| `--target / -t` | pick the environment |
| `--empty` | build with `limit 0` — schema-only smoke test, very cheap in CI |

→ Next: [22 — Git workflow](22-git-workflow.md)
