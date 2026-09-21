# 06 — profiles.yml and connections

`profiles.yml` is the most important file for dbt Core. Without it, nothing runs.

## Anatomy

```yaml
dbt_databricks_src:            # profile name — MUST equal `profile:` in dbt_project.yml
  target: dev                  # which output is used by default
  outputs:
    dev:                       # a "target" = one environment
      type: databricks         # the adapter
      host: dbc-xxxx.cloud.databricks.com
      http_path: /sql/1.0/warehouses/xxxxxxxx
      catalog: dev_tutorial_dev   # Databricks catalog  (alias of `database`)
      schema: default             # default schema when a model doesn't override it
      threads: 1
      token: dapi...              # personal access token
```

The three names that must match:

```
dbt_project.yml : profile: 'dbt_databricks_src'
profiles.yml    : dbt_databricks_src:          ← top-level key
folder name     : dbt_databricks_src/          (convention only, not enforced)
```

## Multiple targets = multiple environments

```yaml
dbt_databricks_src:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: dev_tutorial_dev
      schema: default
      host: dbc-xxxx.cloud.databricks.com
      http_path: /sql/1.0/warehouses/xxxxxxxx
      threads: 1
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
    prod:
      type: databricks
      catalog: prod_tutorial_prod     # ← the only real difference
      schema: default
      host: dbc-xxxx.cloud.databricks.com
      http_path: /sql/1.0/warehouses/xxxxxxxx
      threads: 4
      token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
```

Pick a target at run time — **never** by editing `target:` in the file:

```bash
dbt build                 # uses target: dev
dbt build --target prod   # uses the prod output
dbt build -t prod         # short form
```

## `target.*` variables

Inside any model, macro, test or YAML you can read the active target. This is how you
make code environment-agnostic (see [23 — Deployment](23-deployment-targets-cicd.md)).

| Variable | Value with `dev` here |
| --- | --- |
| `{{ target.name }}` | `dev` |
| `{{ target.database }}` | `dev_tutorial_dev` |
| `{{ target.catalog }}` | `dev_tutorial_dev` *(Databricks alias of `database`)* |
| `{{ target.schema }}` | `default` |
| `{{ target.type }}` | `databricks` |
| `{{ target.threads }}` | `1` |

Verified on dbt-core 1.12 + dbt-databricks 1.10: both `target.database` and
`target.catalog` resolve. `target.database` is the portable one — prefer it if you may
ever switch adapters.

Quick way to inspect them — drop a file in `analyses/` and hit **Compile**:

```sql
-- analyses/target_variables.sql
select
  '{{ target.name }}'     as target_name,
  '{{ target.database }}' as catalog,
  '{{ target.schema }}'   as schema
```

## threads

`threads` = how many models dbt builds in parallel. `1` is safe for learning; production
projects use 4–16 depending on warehouse size.

## Keep secrets out of Git

```yaml
token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
```

```bash
export DBT_DATABRICKS_TOKEN='dapi...'     # macOS/Linux
setx DBT_DATABRICKS_TOKEN "dapi..."       # Windows
```

And in `.gitignore`:

```
profiles.yml
.user.yml
target/
logs/
dbt_packages/
```

> If you keep a sanitised copy for sharing/screenshots (e.g. `profiles_ps.yml` with the
> token blanked), remember it is **not** the file dbt reads — edits there do nothing.

## When the token expires

Symptom: `dbt run` fails with a Databricks auth/connection error that was working
yesterday. Fix: generate a new token in Databricks and replace `token:` in the real
`profiles.yml`. No need to re-init.

→ Next: [07 — Models](07-models.md)
