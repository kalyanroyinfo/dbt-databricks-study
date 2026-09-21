# 17 — Seeds

A **seed** is a small CSV file in `seeds/` that dbt loads into your warehouse as a table.

Think: **lookup tables, mapping tables, parameter files, reference data** — small, static,
rarely changing, version-controlled data.

## Good vs bad seed candidates

✅ country → region mapping, status-code descriptions, category hierarchies, test fixtures,
exchange-rate tables, an "exclude these account ids" list.

❌ anything large, anything that changes often, anything with PII, anything that belongs in
your source system. Seeds are committed to Git — treat them as code, not data.

## Create one

`seeds/lookup.csv` (this repo):

```csv
customer_id,customer_name,customer_email
1,John Doe,john.doe@example.com
2,Jane Smith,jane.smith@example.com
3,Bob Johnson,bob.johnson@example.com
```

The file name becomes the table name: `lookup.csv` → `lookup`.

## Configure the schema

Seeds are configured in their own block in `dbt_project.yml` — they are **not** models:

```yaml
seeds:
  dbt_databricks_src:
    +schema: bronze
```

Without this they land in the target's default schema.

## Load it

```bash
cd dbt_databricks_src

dbt seed                          # load all seeds
dbt seed --select lookup          # just one
dbt seed --full-refresh           # drop and recreate (needed after schema changes)
```

`dbt run` does **not** load seeds. `dbt build` does.

## Use it in a model

Exactly like a model — with `ref()`:

```sql
select *
from {{ ref('lookup') }}
```

Seeds appear in the lineage graph as their own node type.

## Column types and other configs

By default dbt infers types. To pin them:

```yaml
# seeds/properties.yml
version: 2

seeds:
  - name: lookup
    description: "Customer lookup / mapping table"
    config:
      schema: bronze
      column_types:
        customer_id: int
        customer_name: string
        customer_email: string
        quote_columns: false
    columns:
      - name: customer_id
        data_tests:
          - unique
          - not_null
```

Yes — seeds can be tested and documented like any other node.

## Gotchas

- Seeds are **fully replaced** on every `dbt seed`, not merged.
- Very large CSVs are slow and bloat the repo — if it's more than a few thousand rows, load
  it as a real source instead.
- Commas inside values need quoting; set `quote_columns: true` if headers contain special
  characters.

→ Next: [18 — Snapshots (SCD Type 2)](18-snapshots-scd2.md)
