# 02 — dbt Core vs dbt Cloud vs dbt Canvas

## dbt Core

- The **open-source CLI engine**. Free, forever.
- Everything in this repo runs on dbt Core.
- You manage it yourself: Python environment, scheduling, Git, CI/CD, secrets.
- Analogy: Apache Spark is to Databricks what dbt Core is to dbt Cloud.

```bash
uv add dbt-core dbt-databricks   # install the engine + the Databricks adapter
dbt --version
```

## dbt Cloud

- A **managed product built on top of dbt Core** (paid, with a free trial/dev seat).
- Adds: web IDE, managed Git integration, job scheduler, logging/alerting, hosted docs,
  lineage UI, environment variables, semantic layer, RBAC.
- Same concepts, same YAML, same Jinja — you lose nothing by learning Core first.

## dbt Canvas

- A **feature inside dbt Cloud** (not a separate product).
- A drag-and-drop, low-code way to build models visually instead of writing SQL.
- Aimed at non-coders / analysts. If you write code, you'll be faster in the IDE/CLI.

## Which should you learn?

Learn **dbt Core + CLI**. It's free, it's the engine underneath everything else, and
interviews test Core concepts (models, sources, macros, tests, snapshots, configs).
dbt Cloud is a UI over the same ideas.

## Getting the dbt Cloud experience locally

Install the **"dbt Power User"** VS Code extension. You get most of what dbt Cloud's IDE
offers, for free:

- Run / preview a model with one click
- Compiled-SQL preview side-by-side
- Lineage graph (upstream/downstream, expandable with `+`)
- Autocomplete for `ref()`, `source()`, macros, and columns

See [03 — Local setup](03-local-setup.md) for the install and the required file
associations.

→ Next: [03 — Local setup](03-local-setup.md)
