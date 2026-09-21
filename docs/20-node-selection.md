# 20 — Node selection

Node selection = telling dbt **which subset of the DAG to act on**. It works identically
with `run`, `build`, `test`, `compile`, `ls`, `seed` and `snapshot`.

```bash
dbt run --select <selector>
dbt run --exclude <selector>
dbt run -s <selector>            # short form
```

## By name

```bash
dbt run --select bronze_date                       # one model
dbt run --select "bronze_date bronze_store"        # several (space = OR, quote it)
```

## By path / folder

```bash
dbt run --select models/bronze                     # everything under models/bronze
dbt run --select path:models/silver
```

## Graph operators — the important ones

| Selector | Meaning |
| --- | --- |
| `+model` | the model **and all its ancestors** (upstream) |
| `model+` | the model **and all its descendants** (downstream) |
| `+model+` | ancestors **and** descendants |
| `2+model` | only 2 levels upstream |
| `@model` | the model, its descendants, and *their* ancestors (full rebuild set) |

```bash
dbt build --select bronze_sales+        # rebuild bronze_sales and everything after it
dbt build --select +silver_sales_info   # build everything needed to make silver_sales_info
```

This is what you use after changing one model — rebuild the impacted slice, not the whole
project.

## By method

```bash
dbt run  --select tag:daily                        # models tagged daily
dbt run  --select config.materialized:incremental
dbt build --select source:source+                  # everything fed by the `source` source
dbt test --select test_type:singular               # or: generic / unit
dbt build --select result:error+ --state ./prev    # rerun what failed, plus children
dbt run  --select state:modified+ --state ./prev   # CI: only what changed + downstream
```

## Combining

- **space** = OR → `--select bronze_sales bronze_store`
- **comma** = AND → `--select tag:daily,config.materialized:table`
- `--exclude` removes from the selection:

```bash
dbt run --select models/bronze --exclude bronze_date
```

## Saved selectors

For anything you type twice, put it in `selectors.yml`:

```yaml
selectors:
  - name: bronze_only
    definition:
      method: path
      value: models/bronze
```

```bash
dbt run --selector bronze_only
```

## Preview before you run

```bash
dbt ls --select bronze_sales+        # lists the nodes that WOULD be selected
```

Cheap, instant, and saves a lot of accidental full rebuilds.

## Also useful

```bash
dbt retry               # rerun exactly what failed in the previous invocation
dbt run --full-refresh  # force-rebuild incrementals/snapshots in the selection
```

→ Next: [21 — Command cheat sheet](21-commands-cheatsheet.md)
