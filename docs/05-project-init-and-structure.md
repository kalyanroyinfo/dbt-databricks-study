# 05 — `dbt init` and the project structure

## The two things dbt needs

1. A **project** — your code (models, macros, tests, YAML). Defined by `dbt_project.yml`.
2. A **connection (profile)** — how to reach the platform. Defined by `profiles.yml`.

These are independent: one project can use many connections, and one connection can serve
many projects.

## `dbt init`

Run it from the folder that should *contain* the project (here: the repo root):

```bash
dbt init
```

It asks, in order:

| Prompt | Answer used here |
| --- | --- |
| Project name | `dbt_databricks_src` |
| Which database? | `databricks` (only adapters you installed are offered) |
| host | `dbc-xxxx.cloud.databricks.com` (Server hostname, no `https://`) |
| http_path | `/sql/1.0/warehouses/xxxxxxxx` |
| Auth method | `1` → token |
| token | paste it (nothing will be displayed) |
| Use Unity Catalog? | `1` → yes |
| catalog | `dev_tutorial_dev` |
| schema | `default` (we override per layer later) |
| threads | `1` |

Result: a new folder `dbt_databricks_src/` **plus** a `profiles.yml` written to
`~/.dbt/profiles.yml` (`C:\Users\<you>\.dbt\profiles.yml` on Windows).

CLI prompts can pause for several seconds. Don't hit keys — just wait.

## `dbt debug`

```bash
cd dbt_databricks_src     # ← all dbt commands run from INSIDE the project folder
dbt debug
```

Expected: `All checks passed!`

If you run it from the parent folder you get
`Could not find dbt_project.yml` — that's the single most common beginner error.
`dbt debug` also prints which `profiles.yml` it used — handy for debugging.

## Project structure

```
dbt_databricks_src/
├── dbt_project.yml      ← the brain: project name, profile, paths, configs
├── profiles.yml         ← (copied here) connection details
├── models/              ← your SELECT statements — the heart of dbt
│   ├── source/          ← sources.yml (declares raw tables)
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── macros/              ← reusable Jinja functions
├── tests/               ← singular tests; tests/generic/ for custom generic tests
├── seeds/               ← small static CSVs (lookup / mapping tables)
├── snapshots/           ← SCD Type 2 definitions
├── analyses/            ← scratch SQL: compiled but never built
├── logs/                ← dbt.log
└── target/              ← generated: compiled + run SQL, manifest (safe to delete)
```

Delete the auto-generated `models/example/` folder — it's only a sample.

## `dbt_project.yml` — the file everything flows through

```yaml
name: 'dbt_databricks_src'
version: '1.0.0'
profile: 'dbt_databricks_src'     # MUST match a profile name in profiles.yml

model-paths:    ["models"]
analysis-paths: ["analyses"]
test-paths:     ["tests"]
seed-paths:     ["seeds"]
macro-paths:    ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:                     # removed by `dbt clean`
  - "target"
  - "dbt_packages"

models:
  dbt_databricks_src:              # ← project name, then folder names below it
    bronze:
      +materialized: table
      +schema: bronze
    silver:
      +materialized: table
      +schema: silver
    gold:
      +materialized: table
      +schema: gold

seeds:
  dbt_databricks_src:
    +schema: bronze
```

Key points:

- The `*-paths` keys map a **folder on disk** to a **node type**. Rename the folder →
  rename it here too.
- Under `models:`, the first key is the **project name**, then your folder names.
- A `+` prefix marks a **config** (as opposed to a folder name). `+materialized`,
  `+schema`, `+tags`, `+enabled`, `+docs`...
- Warning `Configuration paths exist in your dbt_project.yml file which do not apply to
  any resources` just means you configured a folder (e.g. `gold`) that has no models yet.

## profiles.yml placement

dbt looks for `profiles.yml` in this order:

1. `--profiles-dir` flag / `DBT_PROFILES_DIR` env var
2. the **current project folder**
3. `~/.dbt/profiles.yml`

Copying it into the project folder (next to `dbt_project.yml`) keeps everything together.
**Never commit real tokens** — add `profiles.yml` to `.gitignore` or use env vars
(see [06 — profiles and connections](06-profiles-and-connections.md)).

→ Next: [06 — profiles.yml and connections](06-profiles-and-connections.md)
