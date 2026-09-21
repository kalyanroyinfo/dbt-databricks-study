# 10 — Configurations and precedence

A **config** tells dbt *how* to build a node: materialization, schema, alias, tags,
cluster/partition keys, `enabled`, and so on.

## Three places to set a config

| # | Where | Scope | Syntax |
| --- | --- | --- | --- |
| 1 | `dbt_project.yml` | folder / whole project | `+materialized: table` |
| 2 | properties YAML (`models/bronze/properties.yml`) | one model | `config:` block |
| 3 | in-file `{{ config(...) }}` block | that one model | Jinja |

### 1. Project level — broadest

```yaml
# dbt_project.yml
models:
  dbt_databricks_src:
    bronze:
      +materialized: table
      +schema: bronze
    silver:
      +materialized: table
      +schema: silver
```

Applies to **every model in that folder** (and sub-folders). The `+` prefix distinguishes
a config from a folder name.

### 2. Properties file — per model

```yaml
# models/bronze/properties.yml
version: 2

models:
  - name: bronze_date          # must match the model file name (case-sensitive)
    config:
      materialized: view
      schema: bronze

  - name: bronze_product
    config:
      materialized: view
```

Properties files also hold descriptions, columns and tests — see
[15 — Generic tests](15-generic-tests.md). Name them anything; `properties.yml` (or
`schema.yml`) per folder is the common convention.

### 3. Config block — narrowest, inside the model

```sql
-- models/bronze/bronze_sales.sql
{{ config(materialized='view') }}

select * from {{ source('source', 'fact_sales') }}
```

## Order of precedence

> **The most specific config always wins.**

```
config() block in the model   ← highest priority
        ▲
properties YAML (per model)
        ▲
dbt_project.yml (folder)      ← lowest priority
```

So with `+materialized: table` on the `bronze` folder, plus
`materialized: view` in `properties.yml` for `bronze_date`, plus
`{{ config(materialized='view') }}` inside `bronze_sales.sql`:

| Model | Result |
| --- | --- |
| `bronze_customer` | **table** (project default) |
| `bronze_date` | **view** (properties beat project) |
| `bronze_sales` | **view** (config block beats everything) |

Within the same level, the more specific *path* wins too: a config on
`models/bronze/` overrides one on `models/`.

## Common configs

| Config | Purpose |
| --- | --- |
| `materialized` | `view` / `table` / `incremental` / `ephemeral` / `materialized_view` |
| `schema` | target schema (appended to default unless you override `generate_schema_name`) |
| `alias` | object name different from the file name |
| `tags` | label for selection: `dbt run --select tag:daily` |
| `enabled` | `false` skips the node entirely |
| `database` | target catalog |
| `pre_hook` / `post_hook` | SQL to run before/after the model |
| `file_format`, `partition_by`, `liquid_clustering` | Databricks-specific |

## Which level should you use?

- **Project level** for anything that applies to a whole layer (materialization, schema,
  tags). Least repetition, easiest to review.
- **Properties level** for one-off exceptions plus documentation/tests.
- **Config block** for logic that belongs with the SQL (e.g. incremental settings,
  partitioning) or a deliberate local override.

→ Next: [11 — Custom schemas](11-custom-schemas.md)
