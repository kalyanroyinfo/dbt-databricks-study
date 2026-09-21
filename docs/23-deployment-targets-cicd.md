# 23 — Deployment: targets, parameterisation and CI/CD

Nobody values work that only exists in dev. Deployment in dbt is refreshingly simple:
**same code, different target.**

## The idea

```
dbt build                 →  catalog dev_tutorial_dev
dbt build --target prod   →  catalog prod_tutorial_prod
```

One codebase, zero copy-paste. That only works if **nothing is hard-coded**.

## Step 1 — prepare the prod environment

In Databricks, create the prod catalog and its raw schema:

```sql
create catalog if not exists prod_tutorial_prod;
create schema  if not exists prod_tutorial_prod.source;
```

Populate the prod source (in real life a different feed; for a tutorial, clone dev):

```sql
create table prod_tutorial_prod.source.dim_customer as
select * from dev_tutorial_dev.source.dim_customer;
-- repeat per table: dim_product, dim_store, dim_date, fact_sales, fact_returns, items
```

dbt creates `bronze` / `silver` / `gold` itself.

## Step 2 — add a `prod` output

```yaml
# profiles.yml
dbt_databricks_src:
  target: dev
  outputs:
    dev:
      type: databricks
      host: dbc-xxxx.cloud.databricks.com
      http_path: /sql/1.0/warehouses/xxxxxxxx
      catalog: dev_tutorial_dev
      schema: default
      threads: 1
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
    prod:
      type: databricks
      host: dbc-xxxx.cloud.databricks.com
      http_path: /sql/1.0/warehouses/xxxxxxxx
      catalog: prod_tutorial_prod     # ← the difference
      schema: default
      threads: 4
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
```

> Never switch environments by editing `target:` in the file. Switch with `--target` at
> run time.

## Step 3 — parameterise every hard-coded catalog

Search the project for the literal catalog name. In this project it appears in exactly two
places:

**`models/source/sources.yml`**

```yaml
sources:
  - name: source
    database: "{{ target.database }}"     # was: dev_tutorial_dev
    schema: source
```

**`snapshots/gold_items.yml`**

```yaml
    config:
      database: "{{ target.database }}"   # was: dev_tutorial_dev
      schema: gold
```

Quotes are mandatory — bare `{{ ... }}` is invalid YAML.

`target.database` (Databricks also accepts `target.catalog`) resolves per environment:

| Target | `target.database` |
| --- | --- |
| `dev` | `dev_tutorial_dev` |
| `prod` | `prod_tutorial_prod` |

Models never need parameterising — `ref()` and `source()` already resolve through the
active target.

Verify before deploying:

```bash
dbt compile --select bronze_sales --target prod
cat target/compiled/dbt_databricks_src/models/bronze/bronze_sales.sql
# should show `prod_tutorial_prod`.`source`.`fact_sales`
```

## Step 4 — deploy

```bash
cd dbt_databricks_src
dbt build --target prod
```

`dbt build` runs seeds, models, snapshots **and tests** — so a failed test stops bad data
from propagating. That is why it's the deployment command.

If you see `The profile 'x' does not have a target named 'prod'`, you have a typo in
`profiles.yml` — remember the file dbt actually reads, not your sanitised copy.

## CI/CD with GitHub Actions

**CI (on pull request)** — prove the code compiles and the tests pass:

```yaml
# .github/workflows/dbt_ci.yml
name: dbt CI
on:
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      DBT_DATABRICKS_TOKEN: ${{ secrets.DBT_DATABRICKS_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync
      - name: dbt deps & debug
        working-directory: dbt_databricks_src
        run: |
          uv run dbt deps
          uv run dbt debug --target dev
      - name: dbt build
        working-directory: dbt_databricks_src
        run: uv run dbt build --target dev
```

**CD (on merge to main)** — deploy to prod:

```yaml
# .github/workflows/dbt_cd.yml
name: dbt CD
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      DBT_DATABRICKS_TOKEN: ${{ secrets.DBT_DATABRICKS_TOKEN_PROD }}
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync
      - name: dbt build (prod)
        working-directory: dbt_databricks_src
        run: uv run dbt build --target prod
```

Store tokens in **Settings → Secrets and variables → Actions**, never in the repo.

### Making CI cheap

Rebuilding the whole project on every PR is wasteful. Two options:

```bash
dbt build --select state:modified+ --state ./prod-artifacts   # only what changed + downstream
dbt build --empty                                             # limit 0 — validates SQL, moves no data
```

`state:` needs the previous run's `manifest.json` (download it as a CI artifact from the
last successful main build).

## Other ways to schedule dbt in production

- **Databricks Lakeflow Jobs** — a dbt task type runs your repo natively.
- **Airflow / ADF** — a Bash/Docker operator running `dbt build`.
- **dbt Cloud jobs** — the managed scheduler.

All of them just call `dbt build` with a target. The concepts on this page don't change.

→ Next: [24 — End-to-end walkthrough](24-project-walkthrough.md)
