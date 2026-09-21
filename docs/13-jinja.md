# 13 — Jinja

Jinja is the **templating language** that turns dbt's static SQL into a programming
environment: variables, loops, conditionals, functions. It's the same Jinja used by Flask
to build dynamic HTML — Jinja doesn't care what text it wraps.

## The three delimiters

| Syntax | Name | Use |
| --- | --- | --- |
| `{{ ... }}` | **expression** | prints a value into the output |
| `{% ... %}` | **statement** | does something, prints nothing (`set`, `if`, `for`, `macro`) |
| `{# ... #}` | **comment** | removed at compile time |

Memory hook: *curly braces print, percent signs do.*

```sql
{% set name = 'Kalyan' %}     {# defines — prints nothing #}
select '{{ name }}' as who    {# prints → select 'Kalyan' as who #}
```

## Whitespace control

Add `-` next to the delimiter to strip surrounding whitespace/newlines:

```sql
{%- set name = 'Kalyan' -%}
```

Cosmetic only, but it keeps compiled SQL readable (no stacks of blank lines).

## Loops

```sql
{% set apples = ['Gala', 'Red Delicious', 'Fuji', 'McIntosh', 'Honeycrisp'] %}

{% for a in apples %}
  {{ a }}
{% endfor %}
```

Note `{% endfor %}` (not `endloop`). Inside the loop, `a` is a variable so it needs
`{{ }}` to be printed — bare text is treated as literal text.

## Conditionals

```sql
{% for a in apples %}
    {% if a != 'McIntosh' %}
        {{ a }}
    {% else %}
        I don't like {{ a }}
    {% endif %}
{% endfor %}
```

`{{ }}` inside a string is Jinja's equivalent of a Python f-string:
Python `f"I hate {a}"` → Jinja `I hate {{ a }}`.

## `loop.last` — the trailing-comma fix

The classic dynamic-column-list problem: the last column must not have a comma.

```sql
{% set columns = ['date_sk', 'sales_id', 'gross_amount'] %}

select
{% for col in columns %}
    {{ col }}{% if not loop.last %},{% endif %}
{% endfor %}
from {{ ref('bronze_sales') }}
```

Compiles to:

```sql
select
    date_sk,
    sales_id,
    gross_amount
from `dev_tutorial_dev`.`bronze`.`bronze_sales`
```

Other loop helpers: `loop.first`, `loop.index` (1-based), `loop.index0`, `loop.length`.

## Real example — an incremental-load flag

```sql
{% set incremental_flag = 1 %}
{% set last_load_date = 3 %}

select *
from {{ ref('bronze_sales') }}
{% if incremental_flag == 1 %}
where date_sk > {{ last_load_date }}
{% endif %}
```

With the flag on, it compiles to `... where date_sk > 3`. With it off, the `where` clause
disappears completely. One file handles both full load and incremental load — that's the
whole point.

## Useful built-ins in dbt

| Expression | Meaning |
| --- | --- |
| `{{ this }}` | the current model's relation |
| `{{ target.name }}` / `{{ target.database }}` | active environment ([06](06-profiles-and-connections.md)) |
| `{{ var('my_var', 'default') }}` | project variable, set via `--vars '{my_var: x}'` |
| `{{ env_var('MY_SECRET') }}` | environment variable |
| `{{ run_started_at }}` | run timestamp |
| `{{ log('msg', info=True) }}` | print to the console while compiling |
| `{% do ... %}` | execute an expression without printing |
| `{{ value \| trim }}` | Jinja filters — also `upper`, `length`, `join(', ')`, `default(x)` |

## Always check the compiled SQL

Jinja errors are compile-time errors, and the fastest way to understand them is to look at
the generated SQL:

```bash
dbt compile --select my_model     # → target/compiled/<project>/models/.../my_model.sql
```

Or press **Compile** in dbt Power User. Use `analyses/` as a scratchpad for Jinja
experiments ([19](19-analyses-and-target.md)) — files there compile but never build
anything.

> If the preview pane looks stale in VS Code, save the file; occasionally you need
> `Developer: Reload Window`.

→ Next: [14 — Macros](14-macros.md)
