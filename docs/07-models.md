# 07 — Models

**A model is a `.sql` file in `models/` that contains exactly one `SELECT`.**
That's it. dbt wraps it in the right DDL and builds it on your platform.

## The simplest model

`models/bronze/bronze_sales.sql`:

```sql
{{ config(materialized='view') }}

select *
from {{ source('source', 'fact_sales') }}
```

Rules:

- **No `CREATE TABLE`, no `INSERT`** — dbt generates that.
- **No trailing semicolon** — it breaks the wrapping and throws an error.
- **The file name is the model name and the object name.** `bronze_sales.sql` →
  `bronze_sales` table/view. Referenced as `{{ ref('bronze_sales') }}` — never with
  `.sql`.
- One `SELECT` per file. Use CTEs for multi-step logic.

## What dbt actually runs

After `dbt run`, open `target/run/<project>/models/bronze/bronze_sales.sql`:

```sql
create or replace view `dev_tutorial_dev`.`bronze`.`bronze_sales`
  as
select *
from `dev_tutorial_dev`.`source`.`fact_sales`
```

All the boilerplate — DDL, catalog, schema, `using delta` — is added by dbt.

## Running models

```bash
cd dbt_databricks_src

dbt run                                   # all models
dbt run --select bronze_sales             # one model
dbt run --select "bronze_date bronze_store"   # several (space-separated, quoted)
dbt run --select models/bronze            # a whole folder
dbt run --full-refresh                    # rebuild incrementals/snapshots from scratch
```

See [20 — Node selection](20-node-selection.md) for the full selector syntax.

## Folder layout = medallion architecture

```
models/
├── source/   sources.yml        ← declares raw tables (no SQL)
├── bronze/   bronze_*.sql       ← raw copy, no transformation
├── silver/   silver_*.sql       ← cleaned, joined, enriched
└── gold/     gold_*.sql         ← business-ready facts/dims/KPIs
```

Folders are free-form — dbt only cares that they live under `model-paths`. But the folder
path is what you configure in `dbt_project.yml` and what you select with
`--select models/bronze`, so keep it meaningful.

## A bronze model (raw copy)

```sql
-- models/bronze/bronze_customer.sql
select *
from {{ source('source', 'dim_customer') }}
```

## A silver model (CTEs + macro + aggregation)

```sql
-- models/silver/silver_sales_info.sql
with bronze_sales as (
    select
        sales_id,
        product_sk,
        customer_sk,
        {{ multiply('quantity', 'unit_price') }} as calculated_amount,
        gross_amount,
        payment_method
    from {{ ref('bronze_sales') }}
),

bronze_products as (
    select product_sk, product_name, category
    from {{ ref('bronze_product') }}
),

bronze_customers as (
    select customer_sk, gender
    from {{ ref('bronze_customer') }}
),

joined as (
    select
        bs.sales_id,
        bs.calculated_amount,
        bp.product_name,
        bp.category,
        bc.gender,
        bs.gross_amount,
        bs.payment_method
    from bronze_sales bs
    join bronze_products  bp on bs.product_sk  = bp.product_sk
    join bronze_customers bc on bs.customer_sk = bc.customer_sk
)

select
    category,
    gender,
    sum(gross_amount) as total_gross_amount
from joined
group by category, gender
order by total_gross_amount desc
```

Notes:

- Only the **last** `SELECT` is materialized; the CTEs are steps.
- `with` appears **once**; later CTEs are just `name as ( ... ),`.
- A CTE can reference an earlier CTE — that's a nested CTE and it's how dbt recommends
  replacing nested subqueries (more readable, easier to maintain).
- `{{ ref(...) }}` builds the dependency edge. `{{ multiply(...) }}` is a macro
  ([14 — Macros](14-macros.md)).

## Previewing a model without building it

With the dbt Power User extension:

| Button | What it does |
| --- | --- |
| ▶ **Run/Preview** | Executes the compiled SQL on the warehouse and shows rows — does **not** create the object |
| **Compile** | Shows the final SQL with all Jinja resolved |
| **Lineage** | Shows upstream/downstream nodes |

CLI equivalents:

```bash
dbt compile --select silver_sales_info      # writes compiled SQL to target/compiled/...
dbt show --select silver_sales_info         # prints a sample of rows
```

→ Next: [08 — Sources](08-sources.md)
