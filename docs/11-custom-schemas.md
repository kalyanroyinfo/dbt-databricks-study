# 11 — Custom schemas (a classic interview question)

By default every model lands in the schema from your **target** (`schema: default` in
`profiles.yml`). We want `bronze`, `silver` and `gold` instead.

## Step 1 — declare the schema

```yaml
# dbt_project.yml
models:
  dbt_databricks_src:
    bronze:
      +materialized: table
      +schema: bronze
    silver:
      +materialized: table
      +schema: silver
    gold:
      +materialized: table
      +schema: gold

seeds:
  dbt_databricks_src:
    +schema: bronze
```

(You can also set `schema` in a properties file or a `config()` block — same precedence
rules as [10](10-configs-and-precedence.md). Project level is best: 90% of the time all
models in a layer share a schema.)

## Step 2 — the gotcha

Out of the box dbt **concatenates**: `<target schema>_<custom schema>`. With
`schema: default` in the profile you get:

```
default_bronze,  default_silver,  default_gold        ← not what we want
```

That behaviour lives in a built-in macro called `generate_schema_name`. To change it,
override the macro in your own project.

## Step 3 — override `generate_schema_name`

Create `macros/generate_schema.sql`:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
```

This is dbt's own default macro with the `default_schema ~ '_' ~ ...` concatenation
removed. Now:

| Model | Schema |
| --- | --- |
| no `schema` config | `default` (the target schema) |
| `+schema: bronze` | `bronze` |
| `+schema: silver` | `silver` |

## Step 4 — build

```bash
cd dbt_databricks_src
dbt run
```

dbt **creates the schema if it doesn't exist**, so you don't need to pre-create
`bronze`/`silver`/`gold` in Databricks.

## Why dbt concatenates by default

So two developers running against the same warehouse don't overwrite each other:
`kalyan_bronze` vs `priya_bronze`. Overriding the macro is fine for a single-catalog-per-
environment setup like this one (dev catalog vs prod catalog give the isolation instead).

A common middle ground — keep the prefix in dev, drop it in prod:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

> Sibling macro: `generate_database_name` does the same job for the catalog/database, and
> `generate_alias_name` for the object name.

→ Next: [12 — Materializations](12-materializations.md)
