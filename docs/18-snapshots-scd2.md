# 18 — Snapshots (Slowly Changing Dimension Type 2)

Source tables are **mutable** — a row gets updated and the old value is gone. Analysts
often need to answer *"what did this row look like last month?"*.

A **snapshot** records changes to a mutable table over time. That is exactly
**SCD Type 2**, and dbt gives it to you almost for free.

| | |
| --- | --- |
| SCD Type 1 | overwrite — simple upsert, no history |
| **SCD Type 2** | keep the old row, close it off with a validity window, insert the new one |

Building SCD Type 2 by hand in PySpark/SQL means merge logic, closing old records,
inserting new ones, managing effective dates. dbt does it in ~15 lines of YAML.

## What dbt adds

| Column | Meaning |
| --- | --- |
| `dbt_scd_id` | surrogate key for the snapshot row |
| `dbt_updated_at` | when the snapshot row was written |
| `dbt_valid_from` | when this version became effective |
| `dbt_valid_to` | when it stopped being effective — `NULL` (or a sentinel date) for the current row |

## Step 1 — a clean, de-duplicated source model

Snapshots need **one row per key**. If the raw table can contain multiple rows per key
(e.g. an append-only feed), de-duplicate first, otherwise the `unique_key` breaks.

`models/gold/source_gold_items.sql`:

```sql
with dedup as (
    select
        *,
        row_number() over (partition by id order by update_date desc) as dedup_rn
    from {{ source('source', 'items') }}
)

select
    id,
    name,
    category,
    update_date
from dedup
where dedup_rn = 1
```

## Step 2 — define the snapshot in YAML

Since dbt 1.9, snapshots are defined in **YAML** in `snapshots/`. (The old style — a
`.sql` file with a `{% snapshot %}` block — still works but is legacy.)

`snapshots/gold_items.yml`:

```yaml
snapshots:
  - name: gold_items
    relation: ref('source_gold_items')
    config:
      database: "{{ target.database }}"     # catalog — parameterised for dev/prod
      schema: gold
      unique_key: id
      strategy: timestamp
      updated_at: update_date
      dbt_valid_to_current: "to_date('9999-12-31')"
```

| Key | Meaning |
| --- | --- |
| `relation` | what to snapshot — `ref()` to a model (recommended) or `source()` |
| `unique_key` | the business key; must be unique per run |
| `strategy` | `timestamp` (recommended) or `check` |
| `updated_at` | the timestamp column the `timestamp` strategy compares |
| `dbt_valid_to_current` | value for the open record; omit it and dbt writes `NULL` |

### timestamp vs check

- **`timestamp`** — a row changed if `updated_at` moved. Cheap, reliable, industry
  default. Requires a trustworthy modified-at column.
- **`check`** — compare listed columns value by value. Use when there is no timestamp:

```yaml
      strategy: check
      check_cols: ['name', 'category']     # or: all
```

Extra option: `hard_deletes: invalidate` (or `new_record`) to handle rows that vanish from
the source.

## Step 3 — run it

```bash
cd dbt_databricks_src

dbt snapshot                 # snapshots only
dbt build                    # seeds + models + snapshots + tests, in DAG order
```

Result in `dev_tutorial_dev.gold.gold_items`:

| id | name | category | dbt_valid_from | dbt_valid_to |
| --- | --- | --- | --- | --- |
| 3 | item3 | category3 | 2026-09-19 10:00 | 2026-09-20 14:12 |
| 3 | item3_new | category3 | 2026-09-20 14:12 | 9999-12-31 |

The old version is closed off; the new one is open. That is SCD Type 2.

## Test it yourself

```sql
-- in Databricks, against the SOURCE table
insert into dev_tutorial_dev.source.items
values (3, 'item3_new', 'category3', current_timestamp());
```

```bash
dbt build
```

Re-query the snapshot — you should now see two rows for `id = 3`.

## Gotchas

- Snapshots are **stateful**: the history lives in the target table, not in your repo.
  Dropping it loses history permanently. Never `--full-refresh` a production snapshot
  casually.
- Run snapshots **frequently enough** to catch changes — a change that happens and reverts
  between two runs is invisible.
- Snapshot the *cleanest de-duplicated* input, not the raw feed.
- Reference a snapshot downstream with `{{ ref('gold_items') }}` like any other node.

→ Next: [19 — Analyses and the target folder](19-analyses-and-target.md)
