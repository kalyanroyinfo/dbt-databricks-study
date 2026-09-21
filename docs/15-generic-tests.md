# 15 — Generic (data) tests

Tests are **assertions about your data**. dbt turns each one into a `SELECT` that should
return **zero rows**; any row returned = a failure.

dbt has two families:

- **Generic tests** — reusable, declared in YAML, applied to a column (this page).
- **Singular tests** — one-off SQL files ([16](16-singular-and-custom-generic-tests.md)).

## The four built-in generic tests

| Test | Asserts |
| --- | --- |
| `unique` | no duplicate values in the column |
| `not_null` | no NULLs |
| `accepted_values` | every value is in a given list |
| `relationships` | every value exists in a parent table (referential integrity) |

`unique` + `not_null` on the primary key is non-negotiable in almost every table.

## Where to declare them

In the **properties YAML** of the folder, on the column. Here:
`models/bronze/properties.yml`

```yaml
version: 2

models:
  - name: bronze_sales
    config:
      materialized: view
    columns:
      - name: sales_id
        description: "Primary key for the sales table"
        data_tests:
          - not_null
          - unique

  - name: bronze_store
    config:
      materialized: view
    columns:
      - name: store_sk
        description: "Primary key for the store table"
        data_tests:
          - not_null
          - unique

      - name: store_name
        description: "Name of the store"
        data_tests:
          - accepted_values:
              arguments:
                values: ['MegaMart Manhattan', 'MegaMart Brooklyn', 'MegaMart Austin',
                         'MegaMart San Jose', 'MegaMart Toronto']
              config:
                severity: warn
```

Notes:

- The key is `data_tests:` (it was `tests:` before dbt 1.8 — both still parse, use
  `data_tests`).
- Multiple tests per column is normal.
- Tests with arguments nest them under **`arguments:`**, and test settings under
  **`config:`** (dbt 1.10+). The older flat style — `values:` directly under
  `accepted_values:` — still works but is deprecated.
- Inline lists (`['a', 'b']`) and dash lists are equivalent YAML.

### `relationships`

```yaml
  - name: bronze_sales
    columns:
      - name: customer_sk
        data_tests:
          - relationships:
              arguments:
                to: ref('bronze_customer')
                field: customer_sk
```

## Severity

```yaml
        data_tests:
          - accepted_values:
              arguments:
                values: ['USA', 'Canada']
              config:
                severity: warn     # error (default) | warn
```

| Severity | Effect |
| --- | --- |
| `error` (default) | test fails, `dbt build` stops that branch, exit code ≠ 0 |
| `warn` | logged as a warning, the run continues |

Finer control:

```yaml
              config:
                severity: error
                error_if: ">100"    # only error above 100 failing rows
                warn_if: ">0"
```

Use `warn` for "nice to have" expectations; keep `error` for anything that would corrupt
downstream numbers.

## Running tests

```bash
cd dbt_databricks_src

dbt test                                  # every test in the project
dbt test --select bronze_sales            # tests on one model
dbt test --select source:source           # tests on sources
dbt build                                 # builds models AND runs their tests in order
```

Output reads like:

```
PASS unique_bronze_sales_sales_id ....... [PASS in 2.1s]
WARN 1 accepted_values_bronze_store_store_name ... [WARN 1 in 1.8s]
Done. PASS=4 WARN=1 ERROR=0 SKIP=0 TOTAL=5
```

## Reading a failure

A failing `accepted_values` usually means a **spelling/case mismatch**, not a broken test
— e.g. the warehouse has `MegaMart Manhatten` while your list says `Manhattan`. Check the
actual values first:

```sql
select distinct store_name from dev_tutorial_dev.bronze.bronze_store;
```

The exact SQL dbt ran is saved in `target/compiled/<project>/models/.../<test_name>.sql`.

## Why test the bronze layer at all?

Bronze applies no transformations — but a primary key that arrives duplicated or null is a
**source-system problem**, and you want to know before silver/gold consume it. Testing
early makes the source team's contract explicit instead of silently de-duplicating for
them.

→ Next: [16 — Singular and custom generic tests](16-singular-and-custom-generic-tests.md)
