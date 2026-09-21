# 09 — `ref`, `source` and lineage

Two Jinja functions do 90% of dbt's magic:

| Function | Points at | Example |
| --- | --- | --- |
| `{{ source('src', 'tbl') }}` | a **raw table** dbt did not create | `{{ source('source', 'fact_sales') }}` |
| `{{ ref('model_name') }}` | **another dbt node** (model, seed or snapshot) | `{{ ref('bronze_sales') }}` |

## Why they matter

They do two jobs at once:

1. **Resolve the full name** — `ref('bronze_sales')` compiles to
   `` `dev_tutorial_dev`.`bronze`.`bronze_sales` ``, using the *current target's* catalog
   and the model's configured schema. Change target → the name changes automatically.
2. **Create a dependency edge** — dbt builds the DAG from these calls, so it knows
   `bronze_sales` must exist before `silver_sales_info` runs. Never guess the order
   yourself.

```
dim_customer ─┐
fact_sales  ──┼─► bronze_* ──► silver_sales_info ──► gold_*
dim_product ──┘
  (sources)      (ref)            (ref)
```

## Rules

- `ref()` takes the **model name**, not the file name: `ref('bronze_sales')`, never
  `ref('bronze_sales.sql')`.
- Model names must be **unique across the whole project**, regardless of folder.
- `ref()` also works for **seeds** (`ref('lookup')`) and **snapshots**
  (`ref('gold_items')`).
- Hard-coding `catalog.schema.table` anywhere silently breaks lineage and deployment.

Cross-project / package form (you'll see it in docs):

```sql
{{ ref('other_package', 'model_name') }}
```

## Seeing the lineage

**dbt Power User** → open a model → **Lineage** tab.

- By default you see only **direct** parents/children.
- Click the **`+`** on a node to expand one more level upstream/downstream.
- A model with no `ref`/`source` shows as an isolated box — a red flag that you
  hard-coded a table name.

CLI/graph equivalents:

```bash
dbt ls --select +silver_sales_info      # everything silver_sales_info depends on
dbt ls --select silver_sales_info+      # everything that depends on it
dbt docs generate && dbt docs serve     # full interactive docs site + DAG
```

## Upstream vs downstream

- **Upstream / parents** — what a model reads from (`+model`).
- **Downstream / children** — what reads from this model (`model+`).

Changed a bronze model? Rebuild it *and* everything downstream:

```bash
dbt build --select bronze_sales+
```

→ Next: [10 — Configurations and precedence](10-configs-and-precedence.md)
