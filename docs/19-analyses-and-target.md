# 19 — Analyses and the `target/` folder

Two folders that are easy to ignore and very useful once you know them.

## `analyses/` — the scratchpad

SQL files here are **compiled but never built**. Nothing is created in the warehouse; the
file is not part of your DAG.

Use it for:
- ad-hoc exploration you want to keep and re-run
- testing a macro or a Jinja snippet
- one-off queries for a stakeholder that shouldn't become a model

```sql
-- analyses/1_explore.sql
select * from {{ ref('lookup') }}
```

```sql
-- analyses/query_macro.sql
select {{ multiply(10, 50) }} as test_column
```

```sql
-- analyses/target_variables.sql
select
  '{{ target.name }}'     as target_name,
  '{{ target.database }}' as catalog
```

```bash
dbt compile                               # compiles everything, including analyses/
dbt compile --select resource_type:analysis   # only analyses
```

`ref()` and `source()` work normally, so the SQL is environment-portable. In VS Code, hit
**Compile** or **Run/Preview** with dbt Power User to see the result immediately.

## `target/` — what dbt generated

Created on every `dbt run` / `compile` / `build`. Everything here is disposable.

```
target/
├── compiled/<project>/…    ← your SQL with all Jinja resolved (no DDL wrapper)
├── run/<project>/…         ← the FULL statement sent to the warehouse (with DDL)
├── manifest.json           ← the whole project graph — powers docs, lineage, state:
├── run_results.json        ← timings and status of the last invocation
└── graph.gpickle           ← the compiled DAG
```

### compiled/ vs run/

```sql
-- target/compiled/.../bronze_sales.sql
select * from `dev_tutorial_dev`.`source`.`fact_sales`
```

```sql
-- target/run/.../bronze_sales.sql
create or replace view `dev_tutorial_dev`.`bronze`.`bronze_sales`
  as
select * from `dev_tutorial_dev`.`source`.`fact_sales`
```

This is your **first debugging stop**: when a model fails, read the exact SQL dbt ran and
paste it into a Databricks SQL editor. Tests are there too
(`target/compiled/<project>/tests/...`), wrapped in a `count(*)`.

### Cleaning up

Deleted models leave stale files behind. Clear them:

```bash
dbt clean      # deletes the dirs listed under clean-targets: (target/, dbt_packages/)
```

Safe any time — everything is regenerated on the next run. Both `target/` and `logs/`
belong in `.gitignore`.

## `logs/dbt.log`

The full, verbose log of every invocation — including the SQL, the adapter chatter and
full stack traces that the terminal truncates.

## Bonus — generated docs

`manifest.json` powers the docs site:

```bash
dbt docs generate
dbt docs serve        # opens a local site with models, columns, tests and the full DAG
```

→ Next: [20 — Node selection](20-node-selection.md)
