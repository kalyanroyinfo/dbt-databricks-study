# 26 — Troubleshooting

## `Could not find dbt_project.yml`

You are in the wrong folder. Every dbt command runs from inside the project:

```bash
cd dbt_databricks_src
dbt debug
```

## `The profile 'x' does not have a target named 'prod'`

Typo in `profiles.yml`, or you edited a sanitised copy instead of the file dbt actually
reads. Check which file is used:

```bash
dbt debug     # prints the profiles.yml path it loaded
```

Search order: `--profiles-dir` / `DBT_PROFILES_DIR` → project folder → `~/.dbt/`.
→ [06](06-profiles-and-connections.md)

## Auth / connection error that worked yesterday

Your Databricks **token expired**. Generate a new one
(*Settings → Developer → Access tokens*) and update `token:` in `profiles.yml`. No need to
re-run `dbt init`. → [04](04-databricks-setup.md)

## First run is very slow, then fine

The serverless SQL warehouse auto-suspended and is waking up (~1 min). Don't cancel —
interrupting mid-run can leave partially built objects.

## `Compilation Error` in a model

Almost always Jinja. Check, in order:

1. A typo in `ref()` / `source()` — the name must match the model **name**, no `.sql`.
2. A missing `{% endfor %}` / `{% endif %}` / `{% endmacro %}`.
3. A trailing semicolon at the end of the model.
4. Unquoted Jinja in YAML — `database: {{ target.database }}` must be
   `database: "{{ target.database }}"`.

Then read what dbt actually produced:

```bash
dbt compile --select my_model
cat target/compiled/dbt_databricks_src/models/.../my_model.sql
```

## `Column, variable, or function parameter with name X cannot be resolved`

Not a dbt problem — a SQL problem. The column doesn't exist (or you forgot a `from`, or
aliased a CTE differently). Preview the upstream model and check the real column names.

## A test fails and you don't know why

The exact SQL is in `target/compiled/<project>/models/.../<test_name>.sql`. Run it in
Databricks to see the offending rows. For `accepted_values`, the usual cause is spelling
or case (`Manhatten` vs `Manhattan`):

```sql
select distinct store_name from dev_tutorial_dev.bronze.bronze_store;
```

→ [15](15-generic-tests.md)

## `Configuration paths exist in your dbt_project.yml file which do not apply to any resources`

Harmless warning: you configured a folder (e.g. `gold:`) that has no models yet. It
disappears when you add one.

## Models built into the wrong schema (`default_bronze`)

You set `+schema: bronze` but didn't override `generate_schema_name`. dbt's default
concatenates the target schema. → [11](11-custom-schemas.md)

## Objects left behind after switching materialization

Changing `table` → `view` may leave the old object. Check the schema in Databricks and drop
leftovers manually.

## Stale compile preview in VS Code

Save the file first. If it persists: **Cmd/Ctrl+Shift+P → Developer: Reload Window**. If
Jinja is flagged as a syntax error, the file associations aren't set:

```json
"files.associations": { "*.sql": "jinja-sql", "*.yml": "jinja-yaml" }
```

→ [03](03-local-setup.md)

## `dbt` command not found

The virtualenv isn't active:

```bash
source .venv/bin/activate     # macOS/Linux
.venv\Scripts\activate        # Windows
# or prefix everything:
uv run dbt debug
```

## Old artifacts / weird ghost models

```bash
dbt clean     # wipes target/ and dbt_packages/ — always safe
```

Deleted models leave stale files in `target/` until you do this.
→ [19](19-analyses-and-target.md)

## General debugging order

```bash
dbt debug                         # 1. connection
dbt parse                         # 2. project parses?
dbt compile --select my_model     # 3. Jinja resolves?
cat target/compiled/.../my_model.sql   # 4. is the SQL right?
# 5. paste that SQL into Databricks and read the real error
tail -100 logs/dbt.log            # 6. full stack trace
```
