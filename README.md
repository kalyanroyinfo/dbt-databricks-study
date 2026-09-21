# dbt + Databricks study project

A hands-on dbt Core project built against Databricks Free Edition
(bronze → silver → gold, with sources, tests, seeds, macros and snapshots).

- dbt project: [`dbt_databricks_src/`](dbt_databricks_src/)
- **Study notes: [`docs/`](docs/README.md)** — one concept per file

```bash
cd dbt_databricks_src
dbt debug     # check the connection
dbt build     # seeds + models + snapshots + tests
```
