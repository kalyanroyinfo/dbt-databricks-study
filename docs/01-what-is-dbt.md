# 01 — What is dbt

**dbt = data build tool.** It is the **transformation layer** of a modern data stack.

## ETL vs ELT

- **ETL** — Extract → Transform → Load. Transform happens *before* the warehouse, on a
  separate engine.
- **ELT** — Extract → Load → Transform. Land raw data in the warehouse/lakehouse first,
  then transform it *inside* the warehouse. This is the modern default because storage
  is cheap and warehouse compute is elastic.

dbt owns only the **T** in ELT.

```
Source (API / SQL DB / files)
        │  extract + load   →  done by Airflow, ADF, Fivetran, Databricks Lakeflow Jobs...
        ▼
Warehouse / Lakehouse  (Databricks, Snowflake, BigQuery, Redshift, Fabric...)
        │  transform        →  done by dbt
        ▼
bronze → silver → gold tables/views, ready for BI
```

## What dbt is NOT

| Myth | Reality |
| --- | --- |
| "dbt is an orchestrator" | No. Airflow / ADF / Databricks Jobs / dbt Cloud jobs schedule dbt. |
| "dbt moves data" | No. It never touches data outside the warehouse. |
| "dbt is a warehouse" | No. It has **zero compute and zero storage**. |
| "dbt replaces PySpark" | Only the *transformation* part. PySpark also reads APIs, parses JSON, writes lakes, tunes partitions — dbt does none of that. |

## Where does the compute come from?

dbt compiles your code to plain SQL and sends it to **your platform's compute**. In this
project that is a **Databricks SQL warehouse**. That's why every dbt setup needs an
**adapter** (`dbt-databricks`, `dbt-snowflake`, `dbt-bigquery`, ...) — the adapter is the
driver that knows how to talk to that platform and how to write its SQL dialect.

## Why dbt? (the real selling points)

1. **Modularity / templating** — write the logic once (a macro), reuse it in every model
   and every project, instead of copy-pasting static SQL.
2. **Dependency management** — write `{{ ref('bronze_sales') }}` and dbt figures out the
   build order and draws the lineage graph for you.
3. **Boilerplate removal** — you write `SELECT ...`; dbt generates
   `CREATE OR REPLACE TABLE ... AS SELECT ...`.
4. **Built for data engineering pain points** — incremental loads, SCD Type 2
   (snapshots), data quality tests, seeds/lookup tables are first-class features.
5. **Software engineering practices for SQL** — version control, environments (dev/prod),
   code review, CI/CD, documentation, testing.

## Key vocabulary

| Term | Meaning |
| --- | --- |
| **Model** | A `.sql` file containing a `SELECT`. dbt materializes it as a table/view. |
| **Adapter** | The plugin connecting dbt to a platform (`dbt-databricks` here). |
| **Profile** | The connection details (host, token, catalog, schema). |
| **Target** | A named environment inside a profile (`dev`, `prod`). |
| **Materialization** | How a model is persisted: `view`, `table`, `incremental`, `ephemeral`. |
| **DAG / lineage** | The dependency graph dbt builds from `ref()` and `source()`. |

→ Next: [02 — dbt Core vs dbt Cloud vs Canvas](02-dbt-core-cloud-canvas.md)
