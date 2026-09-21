# 16 — Singular tests and custom generic tests

## Singular tests

A **singular test** is a plain `.sql` file in `tests/` containing one query.
**If it returns rows, the test fails.** (Reverse logic — you write the query that finds
the *bad* rows.)

Use them for business logic: KPI rules, cross-table checks, multi-column conditions —
anything a column-level generic test can't express.

`tests/non_negative_test.sql`:

```sql
select *
from {{ ref('bronze_sales') }}
where gross_amount < 0
   or net_amount < 0
```

Run it:

```bash
cd dbt_databricks_src
dbt test                                  # includes singular tests
dbt test --select non_negative_test       # just this one
```

Notes:
- Use `{{ ref(...) }}` / `{{ source(...) }}` so the test joins the DAG and runs after its
  parents.
- No semicolon; dbt wraps the query in a row count.
- The wrapped SQL is in `target/compiled/<project>/tests/non_negative_test.sql` —
  something like `select count(*) as failures from ( <your query> )`.

More realistic singular tests:

```sql
-- returns rows only if sales and returns disagree on a key
select s.sales_id
from {{ ref('bronze_sales') }} s
left join {{ ref('bronze_returns') }} r on s.sales_id = r.sales_id
where r.sales_id is null and s.is_returned = true
```

```sql
-- alert if gross profit drops more than 20% day over day
with daily as (
    select date_sk, sum(gross_amount) as amt
    from {{ ref('bronze_sales') }}
    group by date_sk
)
select *
from (
    select date_sk, amt, lag(amt) over (order by date_sk) as prev
    from daily
)
where prev is not null and amt < prev * 0.8
```

## Custom generic tests

When the same singular logic repeats, promote it to a **generic test** you can attach to
any column — just like `not_null`.

1. Create `tests/generic/` (the folder name matters).
2. Write a macro wrapped in `{% test ... %}` / `{% endtest %}`, taking `model` and
   `column_name`.

`tests/generic/generic_non_negative.sql`:

```sql
{% test generic_non_negative(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} < 0

{% endtest %}
```

- `model` and `column_name` are **passed in automatically** by dbt from where you attach
  the test — you never pass them by hand.
- Same reverse logic: rows returned = failure.
- Keep the file name and the test name identical.

3. Use it like any built-in test:

```yaml
# models/bronze/properties.yml
  - name: bronze_sales
    columns:
      - name: gross_amount
        description: "Gross amount of the sale"
        data_tests:
          - not_null
          - generic_non_negative
```

```bash
dbt test --select bronze_sales
# → generic_non_negative_bronze_sales_gross_amount ... PASS
```

### With extra arguments

```sql
{% test not_less_than(model, column_name, min_value=0) %}
select *
from {{ model }}
where {{ column_name }} < {{ min_value }}
{% endtest %}
```

```yaml
        data_tests:
          - not_less_than:
              arguments:
                min_value: 10
```

Generic tests can also live in `macros/` — `tests/generic/` is the convention because it
keeps testing code together.

## Which one do I use?

| Situation | Test type |
| --- | --- |
| One column, one rule, reused everywhere | **generic** (built-in or custom) |
| One specific business rule, one place | **singular** |
| Same custom rule appearing 3+ times | promote singular → **custom generic** |

## Bonus: unit tests (dbt 1.8+)

Data tests validate *data*. **Unit tests** validate *model logic* against fixed mock
inputs — no warehouse data involved:

```yaml
unit_tests:
  - name: test_multiply_logic
    model: silver_sales_info
    given:
      - input: ref('bronze_sales')
        rows:
          - {sales_id: 1, quantity: 2, unit_price: 10, gross_amount: 20}
    expect:
      rows:
          - {sales_id: 1, calculated_amount: 20}
```

```bash
dbt test --select test_type:unit
```

→ Next: [17 — Seeds](17-seeds.md)
