# 08 — Sources

A **source** declares a raw table that already exists in your platform — something dbt
reads but did not create.

## Why not just hard-code the table name?

You *can* write:

```sql
select * from dev_tutorial_dev.source.fact_sales      -- ❌ don't
```

It works, but:

- The raw table does **not** appear in your lineage graph.
- The catalog name is hard-coded → breaks when you deploy to prod.
- You cannot attach tests, descriptions or freshness checks to it.

With a source:

```sql
select * from {{ source('source', 'fact_sales') }}    -- ✅
```

you get lineage, environment-portability and testability for free.

## Declaring sources

One YAML file per source schema is the recommended convention. Here:
`models/source/sources.yml`

```yaml
version: 2

sources:
  - name: source                    # the source NAME (used as 1st arg of source())
    database: "{{ target.database }}"   # catalog — parameterised for dev/prod
    schema: source                  # actual schema; defaults to `name` if omitted
    tables:
      - name: fact_sales
      - name: fact_returns
      - name: dim_customer
      - name: dim_date
      - name: dim_store
      - name: dim_product
```

Rules of thumb:

- **One source per schema.** dbt assumes `schema == name` unless you set `schema:`
  explicitly, which is why naming the source after the schema is tidy.
- `database:` is the **catalog** on Databricks. Hard-coding it (`dev_tutorial_dev`) works
  in dev but blocks deployment — use `"{{ target.database }}"` (quotes required, else YAML
  chokes on `{`).

## Using a source

```sql
{{ source('<source name>', '<table name>') }}
```

```sql
-- models/bronze/bronze_sales.sql
select * from {{ source('source', 'fact_sales') }}
```

compiles to:

```sql
select * from `dev_tutorial_dev`.`source`.`fact_sales`
```

## Reading the YAML (a 30-second YAML refresher)

```yaml
sources:            # a key whose value is a LIST
  - name: source    # "-" starts a list item; the item is a dict
    tables:         # a key whose value is another list
      - name: fact_sales
      - name: dim_store
```

Same thing as JSON:

```json
{ "sources": [ { "name": "source",
                 "tables": [ {"name": "fact_sales"}, {"name": "dim_store"} ] } ] }
```

YAML is not something to memorise — it's something to read. Indentation (spaces, never
tabs) is what defines nesting.

## Tests and docs on sources

Sources take the same `description` and `data_tests` blocks as models:

```yaml
tables:
  - name: fact_sales
    description: "Raw sales fact delivered by the OMS team"
    columns:
      - name: sales_id
        data_tests: [not_null, unique]
```

## Source freshness (bonus)

```yaml
  - name: source
    loaded_at_field: _ingested_at
    freshness:
      warn_after:  {count: 12, period: hour}
      error_after: {count: 24, period: hour}
```

```bash
dbt source freshness
```

Tells you whether upstream loads are late — before you waste compute transforming stale
data.

→ Next: [09 — `ref`, `source` and lineage](09-ref-and-lineage.md)
