# 0005 - FastAPI App

## What this demos

This app is the culmination of the configuration steps in `src/configuration/`.
It is a working FastAPI application that demonstrates how the PostgreSQL concepts
built up across those steps come together in practice.

### Permission separation (`0004_users`)

The app connects as the `application` login user - one of several login users
created in `0004_users/run.sql`, each with a different level of access:

| User | Purpose |
|------|---------|
| `application` | The app itself - owns and manages the `application` schema |
| `reporting` | Owns the `reporting` schema, queries reporting views |
| `developer_ro` | Human read-only access across both schemas |
| `performance_monitoring` | `pg_stat_activity` and monitoring views only (`pg_monitor`) |

`application` owns the `application` schema, which means it has full DDL and DML
rights on it - no separate grant is needed. It cannot access the `reporting` schema.
The permission boundary is enforced by the database, not the application code.

### Schema separation (`0003_organisation`)

Objects live on one of two schemas rather than the default `public`:

- `application` - operational tables (`stores`, `staff`, `orders`)
- `reporting` - views and materialised views for read/analytics use cases

This separation means the same privilege system that controls user access also
controls which parts of the schema each role can see. `read_reporting` grants
`USAGE` on `reporting` only - a role without that grant cannot see `reporting`
objects at all.

### Views and materialised views (`0005_app`)

The reporting scripts demonstrate the difference between the two view types:

- **Regular views** (`reporting.orders_by_store`, `reporting.orders_by_staff`) -
  re-executed on every query, always current.

- **Materialised views** (`reporting.staff_count_by_store_mat`, `reporting.orders_by_day`) -
  stored snapshots, potentially stale until manually refreshed:
  ```sql
  REFRESH MATERIALIZED VIEW reporting.staff_count_by_store_mat;
  ```

### Template routes vs reporting scripts

- **Template routes** (`/stores`, `/staff`, `/orders`) - server-rendered HTML,
  write to `application.*` as the `application` user. Demonstrates that owning
  a schema is sufficient for full write access with no additional grants needed.

- **Reporting scripts** (`scripts/`) - standalone Python scripts that connect as
  the `reporting` user. `reporting` has `read_app_data` (SELECT on `application.*`)
  and owns the `reporting` schema. Demonstrates that reporting consumers can query
  application data and manage their own views without write access to `application`.

---

## Setup

```bash
cd src/configuration/0005_app
uv sync
```

## Run

```bash
fastapi dev app/main.py
```

App starts on `http://localhost:8000`.

## Lint / type check

```bash
uv run ruff check app/
uv run pyright app/
```
