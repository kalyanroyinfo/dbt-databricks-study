# 24 — End-to-end walkthrough of this project

Everything from the other notes, in the order you'd actually do it. Follow this to rebuild
`dbt_databricks_src` from an empty folder.

## 0. Prerequisites

Python (a dbt-supported version), Git, uv, VS Code + the Python and dbt Power User
extensions, and a Databricks Free Edition workspace.
→ [03](03-local-setup.md), [04](04-databricks-setup.md)

## 1. Python project

```bash
cd dbt-databricks-study
uv init
echo "3.14" > .python-version
uv sync
uv add dbt-core dbt-databricks
dbt --version

git branch -m main
git add . && git commit -m "initial commit"
```

## 2. Databricks source

Create catalog `dev_tutorial_dev` and schema `source`, then upload the CSVs from
`source_data/` as tables:

```
fact_sales, fact_returns, dim_customer, dim_product, dim_store, dim_date
```

Grab **Server hostname** + **HTTP path** from *Compute → SQL Warehouses → Connection
details*, and create a **personal access token** in *Settings → Developer*.

## 3. Initialise dbt

```bash
dbt init          # name: dbt_databricks_src → databricks → host/http_path/token
                  # unity catalog: yes, catalog: dev_tutorial_dev, schema: default, threads: 1

cp ~/.dbt/profiles.yml dbt_databricks_src/profiles.yml
cd dbt_databricks_src
dbt debug         # expect: All checks passed!
```

Delete `models/example/` and create the layer folders:

```
models/source/  models/bronze/  models/silver/  models/gold/
```

## 4. Declare sources

`models/source/sources.yml` → [08](08-sources.md)

```yaml
version: 2
sources:
  - name: source
    database: "{{ target.database }}"
    schema: source
    tables:
      - name: fact_sales
      - name: fact_returns
      - name: dim_customer
      - name: dim_date
      - name: dim_store
      - name: dim_product
```

## 5. Bronze layer

One model per source table, e.g. `models/bronze/bronze_sales.sql`:

```sql
select * from {{ source('source', 'fact_sales') }}
```

Configure the layer in `dbt_project.yml`:

```yaml
models:
  dbt_databricks_src:
    bronze:
      +materialized: table
      +schema: bronze
```

Add `macros/generate_schema.sql` so the schema is `bronze` and not `default_bronze`
→ [11](11-custom-schemas.md).

```bash
dbt run
dbt run --select models/bronze          # or just this layer
```

Check `dev_tutorial_dev.bronze` in Databricks. Then look at
`target/run/dbt_databricks_src/models/bronze/bronze_sales.sql` to see the DDL dbt
generated → [19](19-analyses-and-target.md).

## 6. Branch before going further

```bash
git switch -c feature_dbt_layers
```

## 7. Data quality

`models/bronze/properties.yml` → [15](15-generic-tests.md)

```yaml
version: 2
models:
  - name: bronze_sales
    config:
      materialized: view
    columns:
      - name: sales_id
        data_tests: [not_null, unique]
      - name: gross_amount
        data_tests:
          - not_null
          - generic_non_negative
```

Plus a singular test `tests/non_negative_test.sql` and a custom generic test
`tests/generic/generic_non_negative.sql` → [16](16-singular-and-custom-generic-tests.md).

```bash
dbt test
```

## 8. Seeds

`seeds/lookup.csv` + `seeds: dbt_databricks_src: +schema: bronze` in `dbt_project.yml`.

```bash
dbt seed
```

→ [17](17-seeds.md)

## 9. Macros and Jinja

`macros/multiply.sql` → [14](14-macros.md). Experiment in `analyses/`.

## 10. Silver layer

`models/silver/silver_sales_info.sql` — CTEs joining bronze sales + products + customers,
using `{{ multiply('quantity','unit_price') }}`, aggregated to sales by category × gender
→ [07](07-models.md).

```bash
dbt run --select models/silver
```

## 11. Gold layer + snapshot (SCD Type 2)

Create an `items` table in the `source` schema, add a de-duplicating model
`models/gold/source_gold_items.sql`, then `snapshots/gold_items.yml`
→ [18](18-snapshots-scd2.md).

```bash
dbt snapshot
dbt build          # everything, in dependency order
```

Update a row in the source and run `dbt build` again — you should see two versions of that
key with `dbt_valid_from` / `dbt_valid_to`.

## 12. Commit and merge

```bash
git add . && git commit -m "bronze/silver/gold, tests, seeds, snapshot"
git switch main
git merge feature_dbt_layers
```

## 13. Deploy to prod

Create `prod_tutorial_prod` + its `source` schema, add a `prod` output to `profiles.yml`,
replace hard-coded catalogs with `"{{ target.database }}"`, then:

```bash
dbt build --target prod
```

→ [23](23-deployment-targets-cicd.md)

## Final layout

```
dbt_databricks_src/
├── dbt_project.yml
├── profiles.yml                     (gitignored)
├── models/
│   ├── source/sources.yml
│   ├── bronze/bronze_*.sql + properties.yml
│   ├── silver/silver_sales_info.sql
│   └── gold/source_gold_items.sql
├── macros/generate_schema.sql, multiply.sql
├── tests/non_negative_test.sql
│   └── generic/generic_non_negative.sql
├── seeds/lookup.csv
├── snapshots/gold_items.yml
└── analyses/1_explore.sql, query_macro.sql
```

→ Next: [25 — Interview questions](25-interview-questions.md)
