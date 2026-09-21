# 04 — Databricks setup (the platform dbt will use)

dbt has no compute, so we need a platform. **Databricks Free Edition** is used here
because it needs no credit card and no business email. Everything below maps 1:1 to
Snowflake/BigQuery/Fabric — only names change.

## 1. Create the workspace

1. Search for **"Databricks Free Edition"**.
2. On the pricing page, click **"Looking for Databricks Free Edition?"** — *not* Express
   Setup (that one is a time-limited trial).
3. Sign up with a normal Google/Microsoft email, then log back in.

## 2. Create the catalog and schemas

In **Catalog** → **+** → **Create catalog**:

| Object | Name here | Equivalent to |
| --- | --- | --- |
| Catalog | `dev_tutorial_dev` | a database |
| Schema | `source` | raw landing zone |
| Schema | `bronze` / `silver` / `gold` | created automatically by dbt |

You only need to create the **catalog** and the **`source`** schema by hand. dbt creates
`bronze`, `silver` and `gold` on the fly when it builds models (see
[11 — Custom schemas](11-custom-schemas.md)).

## 3. Load the source tables

For each CSV in this repo's `source_data/` folder:

**Catalog → your catalog → `source` schema → Create → Table → Browse → upload CSV → Create table**

Databricks converts the CSV into a managed **Delta** table. Tables used here:

```
fact_sales, fact_returns, dim_customer, dim_product, dim_store, dim_date
```

> Double-check the **catalog** and **schema** dropdowns on the upload screen — landing a
> table in the wrong schema is the #1 silly mistake.

## 4. Get the connection details

**Compute → SQL Warehouses → (your warehouse) → Connection details**

Copy:
- **Server hostname** → dbt's `host`
- **HTTP path** → dbt's `http_path`

The Free Edition includes a small serverless SQL warehouse. It auto-suspends, so the
**first `dbt run` after a pause takes ~1 minute** while it wakes up — that is normal, do
not cancel it.

## 5. Create a personal access token

**Settings → Developer → Access tokens → Manage → Generate new token**

- Give it a name (e.g. `dbt-youtube`) and a lifetime.
- **Copy the value immediately** — it is shown only once.

> When you paste a token into a terminal prompt, nothing appears on screen (not even
> `***`). That's intentional. Paste and press Enter.

Tokens expire. When they do, `dbt run` fails with a database/auth error — just generate a
new token and update `token:` in `profiles.yml`. You do **not** need to re-run `dbt init`.

## 6. Where things land

```
dev_tutorial_dev                 ← catalog
 ├── source   (you upload CSVs here)
 ├── bronze   (created by dbt)
 ├── silver   (created by dbt)
 └── gold     (created by dbt)
```

→ Next: [05 — `dbt init` and project structure](05-project-init-and-structure.md)
