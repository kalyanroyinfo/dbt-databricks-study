# 14 — Macros

**A macro is a function written in Jinja.** Same idea as a Python `def`: write the logic
once, call it everywhere. Macros live in `macros/*.sql`.

## Anatomy

```sql
{% macro macro_name(arg1, arg2) %}
   ... SQL / Jinja ...
{% endmacro %}
```

Only those two lines are macro-specific; everything between them is ordinary SQL + Jinja.

## Example — `multiply`

`macros/multiply.sql`:

```sql
{% macro multiply(col1, col2) -%}
    {{ col1 }} * {{ col2 }}
{%- endmacro %}
```

Used in a model:

```sql
select
    {{ multiply('quantity', 'unit_price') }} as calculated_amount
from {{ ref('bronze_sales') }}
```

Compiles to:

```sql
select
    quantity * unit_price as calculated_amount
from `dev_tutorial_dev`.`bronze`.`bronze_sales`
```

Remember the `{{ }}` around the arguments inside the macro — without them Jinja prints the
literal words `col1 * col2`.

## Conventions

- **File name = macro name** (`multiply.sql` → `multiply`). Not enforced, but it's how
  everyone finds things.
- One macro per file for anything non-trivial.
- Macros can call other macros, and can call `ref()` / `source()`.

## A more useful macro

```sql
-- macros/cents_to_dollars.sql
{% macro cents_to_dollars(column_name, decimal_places=2) -%}
    round( {{ column_name }} / 100.0, {{ decimal_places }} )
{%- endmacro %}
```

```sql
select {{ cents_to_dollars('amount_cents') }} as amount_usd
from {{ ref('bronze_sales') }}
```

## Testing a macro quickly

Put a throwaway file in `analyses/` and hit **Compile**:

```sql
-- analyses/query_macro.sql
select {{ multiply(10, 50) }} as test_column
```

Compiles to `select 10 * 50 as test_column`. Files in `analyses/` are compiled but never
materialized ([19](19-analyses-and-target.md)).

## Macros dbt calls for you

Some macro names are special — define them and dbt uses yours instead of the built-in:

| Macro | Controls |
| --- | --- |
| `generate_schema_name` | which schema a model lands in ([11](11-custom-schemas.md)) |
| `generate_database_name` | which catalog/database |
| `generate_alias_name` | the object name |

## Running a macro standalone

```bash
dbt run-operation my_macro --args '{arg1: value}'
```

Handy for maintenance jobs (grants, vacuum, ad-hoc DDL).

## Packages = other people's macros

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
```

```bash
dbt deps      # installs into dbt_packages/
```

Then use them namespaced:

```sql
{{ dbt_utils.star(from=ref('bronze_sales'), except=['created_at']) }}
{{ dbt_utils.generate_surrogate_key(['customer_sk', 'date_sk']) }}
```

`dbt_utils` also ships extra generic tests (`expression_is_true`, `unique_combination_of_columns`,
`accepted_range`, ...). `dbt-expectations` and `codegen` are the other two packages worth
knowing.

→ Next: [15 — Generic tests](15-generic-tests.md)
