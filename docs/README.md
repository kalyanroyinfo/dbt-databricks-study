# dbt Study Notes

Short, self-contained notes on how dbt works — one concept per file, so you can open
any single file and understand that topic without reading everything else.

All examples are grounded in this repo:

| Thing | Value here |
| --- | --- |
| dbt project folder | `dbt_databricks_src/` |
| Project + profile name | `dbt_databricks_src` |
| Platform (adapter) | Databricks (`dbt-databricks`) |
| Catalog (dev) | `dev_tutorial_dev` |
| Schemas | `source`, `bronze`, `silver`, `gold` |
| dbt-core version | 1.12.x |
| Python | 3.14 (venv managed by `uv`) |

## Learning path

### 1. Foundations
- [01 — What is dbt](01-what-is-dbt.md)
- [02 — dbt Core vs dbt Cloud vs Canvas](02-dbt-core-cloud-canvas.md)

### 2. Setup
- [03 — Local setup (Python, git, uv, VS Code)](03-local-setup.md)
- [04 — Databricks setup (catalog, schema, warehouse, token)](04-databricks-setup.md)
- [05 — `dbt init` and project structure](05-project-init-and-structure.md)
- [06 — profiles.yml and connections](06-profiles-and-connections.md)

### 3. Building
- [07 — Models](07-models.md)
- [08 — Sources](08-sources.md)
- [09 — `ref`, `source` and lineage](09-ref-and-lineage.md)
- [10 — Configurations and precedence](10-configs-and-precedence.md)
- [11 — Custom schemas](11-custom-schemas.md)
- [12 — Materializations](12-materializations.md)

### 4. Templating
- [13 — Jinja](13-jinja.md)
- [14 — Macros](14-macros.md)

### 5. Data quality
- [15 — Generic tests](15-generic-tests.md)
- [16 — Singular and custom generic tests](16-singular-and-custom-generic-tests.md)

### 6. Extra node types
- [17 — Seeds](17-seeds.md)
- [18 — Snapshots (SCD Type 2)](18-snapshots-scd2.md)
- [19 — Analyses and the `target/` folder](19-analyses-and-target.md)

### 7. Running and shipping
- [20 — Node selection](20-node-selection.md)
- [21 — Command cheat sheet](21-commands-cheatsheet.md)
- [22 — Git workflow](22-git-workflow.md)
- [23 — Deployment, targets and CI/CD](23-deployment-targets-cicd.md)

### 8. Putting it together
- [24 — End-to-end walkthrough of this project](24-project-walkthrough.md)
- [25 — Interview questions](25-interview-questions.md)
- [26 — Troubleshooting](26-troubleshooting.md)

## The 10-second version

dbt is the **T** in **ELT**. It does not extract, it does not load, it does not own
compute. You write `SELECT` statements; dbt wraps them in DDL, resolves dependencies,
and runs them **on your warehouse** (here: a Databricks SQL warehouse).

```bash
cd dbt_databricks_src   # every dbt command runs from the project folder
dbt debug               # is my connection healthy?
dbt build               # run seeds + models + snapshots + tests, in dependency order
```
