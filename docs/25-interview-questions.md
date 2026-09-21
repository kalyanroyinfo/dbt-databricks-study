# 25 — Interview questions (quick revision)

Short answers you should be able to give without thinking. Each links to the full note.

## Fundamentals

**What is dbt?**
The transformation (T) layer of ELT. You write `SELECT` statements; dbt adds the DDL,
resolves dependencies and executes on your warehouse's compute. → [01](01-what-is-dbt.md)

**Does dbt have its own compute?**
No. Zero compute, zero storage. It borrows the platform's — a Databricks SQL warehouse
here. → [01](01-what-is-dbt.md)

**What's an adapter?**
The plugin that connects dbt to a platform and speaks its SQL dialect: `dbt-databricks`,
`dbt-snowflake`, `dbt-bigquery`. → [01](01-what-is-dbt.md)

**dbt Core vs dbt Cloud?**
Core = open-source CLI engine, self-managed. Cloud = managed product on top (IDE,
scheduler, Git integration, hosted docs). Canvas = a drag-and-drop feature inside Cloud.
→ [02](02-dbt-core-cloud-canvas.md)

**Does dbt replace PySpark?**
Only the transformation part. PySpark also extracts, parses JSON, calls APIs, writes lakes
and tunes partitions. → [01](01-what-is-dbt.md)

## Project mechanics

**What is a model?**
A `.sql` file in `models/` holding one `SELECT`, materialized as a view/table by dbt. No
DDL, no semicolon. → [07](07-models.md)

**`ref()` vs `source()`?**
`source()` points at a raw table dbt didn't create; `ref()` points at another dbt node.
Both resolve the full name **and** create the dependency edge that builds the DAG.
→ [09](09-ref-and-lineage.md)

**Why not hard-code `catalog.schema.table`?**
You lose lineage, you lose testability, and the code breaks the moment you deploy to
another environment. → [08](08-sources.md)

**What's in `dbt_project.yml`?**
Project name, the profile to use, the folder→node-type paths, `clean-targets`, and
project-level configs. → [05](05-project-init-and-structure.md)

**Where can configs be set, and which wins?**
Three places — `dbt_project.yml` (folder), properties YAML (per model), `{{ config() }}`
block (in file). **Most specific wins:** config block > properties > project.
→ [10](10-configs-and-precedence.md)

**Name the materializations.**
`view`, `table`, `incremental`, `ephemeral`, `materialized_view`.
→ [12](12-materializations.md)

**How do you land models in custom schemas?**
Set `+schema:` per folder, then override the `generate_schema_name` macro — otherwise dbt
concatenates `<target_schema>_<custom_schema>`. → [11](11-custom-schemas.md)

## Jinja and macros

**What is Jinja used for in dbt?**
Templating: variables, loops, conditionals, functions — turning static SQL into dynamic,
reusable SQL. `{{ }}` prints, `{% %}` does, `{# #}` comments.
→ [13](13-jinja.md)

**What's a macro?**
A Jinja function in `macros/`, defined with `{% macro %}...{% endmacro %}` — write once,
reuse everywhere. → [14](14-macros.md)

**How do you avoid a trailing comma in a Jinja-generated column list?**
`{% if not loop.last %},{% endif %}`. → [13](13-jinja.md)

## Testing

**What kinds of tests does dbt have?**
Generic (reusable, YAML-declared: `unique`, `not_null`, `accepted_values`,
`relationships`), singular (one-off SQL in `tests/`), custom generic
(`{% test %}` in `tests/generic/`), and unit tests (mock inputs, dbt 1.8+).
→ [15](15-generic-tests.md), [16](16-singular-and-custom-generic-tests.md)

**How does a dbt test pass or fail?**
Every test is a query that must return **zero rows**. Rows returned = failure.
→ [16](16-singular-and-custom-generic-tests.md)

**How do you make a test warn instead of fail?**
`config: severity: warn` (also `error_if` / `warn_if`). → [15](15-generic-tests.md)

**When would you write a singular test?**
Business/KPI logic spanning multiple columns or tables — anything a column-level generic
test can't express. → [16](16-singular-and-custom-generic-tests.md)

## Seeds and snapshots

**What is a seed?**
A small static CSV in `seeds/`, loaded by `dbt seed`, used for lookup/mapping/reference
data. Referenced with `ref()`. → [17](17-seeds.md)

**What is a snapshot?**
dbt's implementation of **SCD Type 2** — it records changes to a mutable table over time
using `dbt_valid_from` / `dbt_valid_to`. → [18](18-snapshots-scd2.md)

**Which snapshot strategies exist?**
`timestamp` (compare an `updated_at` column — recommended) and `check` (compare listed
columns). → [18](18-snapshots-scd2.md)

**Why de-duplicate before a snapshot?**
`unique_key` must be unique per run; duplicates break the SCD logic. Use
`row_number() over (partition by key order by updated_at desc) = 1`.
→ [18](18-snapshots-scd2.md)

## Running and shipping

**`dbt run` vs `dbt build`?**
`run` = models only. `build` = seeds + models + snapshots + tests in DAG order, stopping a
branch when its tests fail. `build` is what you schedule.
→ [21](21-commands-cheatsheet.md)

**What is node selection?**
Choosing the subgraph to act on: `--select model`, `models/bronze`, `+model` (upstream),
`model+` (downstream), `tag:x`, `state:modified+`.
→ [20](20-node-selection.md)

**What's in the `target/` folder?**
`compiled/` (Jinja resolved), `run/` (full DDL sent to the warehouse), `manifest.json`
(the project graph), `run_results.json`. Cleared with `dbt clean`.
→ [19](19-analyses-and-target.md)

**How do you deploy to prod?**
Add a `prod` output in `profiles.yml`, parameterise every hard-coded catalog with
`{{ target.database }}`, then `dbt build --target prod`.
→ [23](23-deployment-targets-cicd.md)

**How do you make CI cheap?**
`dbt build --select state:modified+ --state <prev manifest>`, or `dbt build --empty`.
→ [23](23-deployment-targets-cicd.md)

**Where does dbt look for `profiles.yml`?**
`--profiles-dir` / `DBT_PROFILES_DIR` → the project folder → `~/.dbt/profiles.yml`.
→ [06](06-profiles-and-connections.md)

## Trick questions

**Can you use `ref()` in a macro?** Yes.
**Can you test a source?** Yes — same `data_tests:` block.
**Can you test a seed or a snapshot?** Yes.
**Does `dbt run` load seeds?** No — `dbt seed` or `dbt build`.
**Does a semicolon at the end of a model work?** No — it breaks the generated DDL.
**Is `analyses/` part of the DAG?** No — compiled, never built.
