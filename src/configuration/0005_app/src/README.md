# 0005 — FastAPI App

## What this demos

This app is the culmination of the configuration steps in `src/configuration/`.
It is a working FastAPI application that demonstrates how the PostgreSQL concepts
built up across those steps come together in practice.

### Permission separation (`0004_users`)

The app connects as the `application` login user — one of several login users
created in `0004_users/run.sql`, each with a different level of access:

| User | Purpose |
|------|---------|
| `application` | The app itself — CRUD on data, read reporting |
| `migrations` | Schema changes — DDL + write access |
| `developer_ro` | Human read-only access across both schemas |
| `break_glass` | Emergency full access |
| `performance_monitoring` | `pg_stat_activity` and monitoring views only (`pg_monitor`) |

`application` holds two roles:
- `write_app_data` — SELECT, INSERT, UPDATE, DELETE on `application.*`
- `read_reporting` — SELECT on `reporting.*`

This means the app can write operational data and read reporting views, but
cannot run DDL, cannot access monitoring metadata, and cannot touch objects
outside those two schemas. The permission boundary is enforced by the database,
not the application code.

### Schema separation (`0003_organisation`)

Objects live on one of two schemas rather than the default `public`:

- `application` — operational tables (`stores`, `staff`, `orders`)
- `reporting` — views and materialised views for read/analytics use cases

This separation means the same privilege system that controls user access also
controls which parts of the schema each role can see. `read_reporting` grants
`USAGE` on `reporting` only — a role with that grant cannot see `application`
tables at all.

### Views and materialised views (`0002_data`, `0005_app`)

The API routes demonstrate the difference between the two view types in practice:

- **Regular views** (`reporting.orders_by_store`, `reporting.orders_by_staff`) —
  re-executed on every request. Add a store via the template route, hit the API,
  and the result is immediately current.

- **Materialised views** (`reporting.staff_count_by_store_mat`, `reporting.orders_by_day`) —
  stored snapshots. Add a store via the template route, hit the API, and the
  result is stale until you manually run:
  ```sql
  REFRESH MATERIALIZED VIEW reporting.staff_count_by_store_mat;
  ```
  This is intentional — the app does not refresh them automatically, making the
  staleness visible.

### Template routes vs API routes

The app has two kinds of routes, each backed by a different part of the schema:

- **Template routes** (`/stores`, `/staff`) — server-rendered HTML, write to
  `application.*` via the `write_app_data` role. Demonstrates that an application
  role can insert data without needing schema-level privileges.

- **API routes** (`/api/*`) — JSON responses, read from `reporting.*` via the
  `read_reporting` role. Demonstrates that reporting consumers only need SELECT
  on the reporting schema — they never touch the underlying operational tables directly.

---

## Setup

```bash
cd src/configuration/0005_app/src
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

