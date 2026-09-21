# 03 — Local setup (Python, Git, uv, VS Code)

Everything dbt Core needs on your machine, in order.

## 1. VS Code

Download from <https://code.visualstudio.com/>, then `File → Open Folder` on your project
root (this repo's root is `dbt-databricks-study/`).

## 2. Git

```bash
git --version      # verify; if missing, install from https://git-scm.com/downloads
```

Git matters here because dbt development is code development: feature branches, commits,
pull requests, CI/CD.

## 3. Python (mind the version!)

dbt does **not** support every Python version. Check the compatibility matrix before
installing: <https://docs.getdbt.com/faqs/Core/install-python-compatibility>

```bash
python3 --version
```

If your version is unsupported, install a supported one from
<https://www.python.org/downloads/> (scroll to **"Looking for a specific release?"**).

> **Windows installer tip:** tick **"Add python.exe to PATH"** or dbt/VS Code will not
> find the interpreter.

Having several Python versions installed side by side is fine — the newest one you
installed wins on `PATH`, and each project pins its own version anyway (next step).

## 4. uv (the package manager)

`uv` is the modern replacement for `pip` + `venv` + `requirements.txt`.

```bash
pip install uv          # or: brew install uv  /  curl -LsSf https://astral.sh/uv/install.sh | sh
uv --version
```

### Initialise the project

```bash
cd /path/to/dbt-databricks-study
uv init                 # creates pyproject.toml, .python-version, README.md, .gitignore, and git init
```

Pin the Python version for *this* project by editing `.python-version`:

```
3.14
```

Then create the virtual environment from that pin:

```bash
uv sync                 # creates .venv/ matching .python-version and installs dependencies
```

### Install dbt

```bash
uv add dbt-core
uv add dbt-databricks   # the adapter — swap for dbt-snowflake / dbt-bigquery / etc.
```

`uv add` records the package in **`pyproject.toml`** under `[project] dependencies` —
that file replaces `requirements.txt`.

### Useful uv equivalents

| pip | uv |
| --- | --- |
| `pip install X` | `uv add X` |
| `pip uninstall X` | `uv remove X` |
| `pip freeze > requirements.txt` | `uv pip freeze > requirements.txt` |
| `pip install -r requirements.txt` | `uv add -r requirements.txt` |

### Activating the venv

`uv run` and `uv add` handle the venv automatically. To activate it manually:

```bash
source .venv/bin/activate        # macOS / Linux
.venv\Scripts\activate           # Windows
```

You're in the venv when the prompt shows the project/venv name. In VS Code, the terminal
dropdown / status bar shows the interpreter (e.g. `dbt-databricks-study 3.14`). If you only
see a bare `Python 3.x`, you're on the global interpreter — activate first.

### Verify dbt

```bash
dbt --version    # shows dbt-core + installed adapter versions
dbt              # prints the help/command list — if you see it, install is healthy
```

## 5. VS Code extensions

| Extension | Why |
| --- | --- |
| **Python** (Microsoft) | Interpreter selection, Pylance IntelliSense, debugging, linting |
| **dbt Power User** | Run/preview models, compiled SQL, lineage graph, autocomplete |

### Configure dbt Power User (do not skip)

YAML and SQL files contain Jinja, which the plain YAML/SQL parsers cannot understand.
Click the **dbt** status-bar item → **Setup Extension** → **Associate File Types**, or set
it manually in `settings.json`:

```json
{
  "files.associations": {
    "*.sql": "jinja-sql",
    "*.yml": "jinja-yaml"
  }
}
```

After this, `dbt_project.yml` shows as **Jinja YAML** and Jinja stops being flagged as a
syntax error.

## 6. First commit

`uv init` already ran `git init`, so:

```bash
git branch -m main                 # rename master → main
git add .
git commit -m "initial commit"
```

→ Next: [04 — Databricks setup](04-databricks-setup.md)
