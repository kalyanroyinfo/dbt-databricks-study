# 12 — Materializations

A materialization is the **strategy dbt uses to persist a model**. You choose it with the
`materialized` config; dbt generates the matching DDL.

| Materialization | What dbt runs | Use it for |
| --- | --- | --- |
| `view` | `create or replace view ... as (select ...)` | light transforms, always-fresh, no storage cost |
| `table` | `create or replace table ... as (select ...)` | expensive logic queried often |
| `incremental` | creates once, then `merge`/`insert` only new rows | big fact tables |
| `ephemeral` | not built at all — inlined as a CTE into its children | small intermediate logic |
| `materialized_view` | platform-native MV (adapter-dependent) | auto-refreshing aggregates |

## Setting it

```yaml
# dbt_project.yml — whole folder
models:
  dbt_databricks_src:
    bronze:
      +materialized: table
```

```sql
-- or per model
{{ config(materialized='view') }}
```

## view vs table

- **view** — no storage, always current, but recomputes on every query.
- **table** — fast reads, costs storage, stale until the next `dbt run`.

Switching from `table` to `view` (or back) and re-running may leave the old object behind
depending on permissions — check the schema and drop leftovers if you see both.

## Incremental models

```sql
{{ config(
    materialized='incremental',
    unique_key='sales_id',
    incremental_strategy='merge'
) }}

select *
from {{ source('source', 'fact_sales') }}

{% if is_incremental() %}
  -- only on subsequent runs; `this` = the existing table
  where date_sk > (select coalesce(max(date_sk), 0) from {{ this }})
{% endif %}
```

- First run: builds the full table (the `is_incremental()` block is skipped).
- Later runs: only the filtered rows are processed and merged on `unique_key`.
- `{{ this }}` is the model's own relation.
- `dbt run --full-refresh` rebuilds it from scratch.

Databricks strategies: `append`, `merge` (default with a `unique_key`),
`insert_overwrite`, `replace_where`, `microbatch`.

## Ephemeral

```sql
{{ config(materialized='ephemeral') }}
select ... -- gets inlined as a CTE in every downstream model
```

Nothing is created in the warehouse and you cannot query it directly — useful for small
shared logic you don't want to persist.

## Snapshots are separate

SCD Type 2 has its own node type and its own command (`dbt snapshot`), not a
materialization config — see [18 — Snapshots](18-snapshots-scd2.md).

→ Next: [13 — Jinja](13-jinja.md)
