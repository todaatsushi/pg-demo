"""
db.py — database connection pool.

Uses psycopg 3 (the modern PostgreSQL driver) with its built-in
ConnectionPool. A single module-level pool instance is shared across
the whole application.

Connection details are hardcoded here for this demo. In production
these would come from environment variables or a secrets manager.

DSN breakdown:
  postgresql://<user>:<password>@<host>:<port>/<dbname>
  - user:     application  (created in 0004_users/run.sql)
  - password: CRUD
  - host:     localhost    (postgres exposed on host via docker-compose port 5432)
  - port:     5432
  - dbname:   grocery_store (created in 0001_databases/run.sql)

The `application` role has:
  - write_app_data  → SELECT, INSERT, UPDATE, DELETE on application.*
  - read_reporting  → SELECT on reporting.*
  - CONNECT on grocery_store
"""

from psycopg.rows import dict_row as dict_row
from psycopg_pool import ConnectionPool

DSN = "postgresql://application:CRUD@localhost:5432/grocery_store"

# min_size=1 keeps one connection warm at all times.
# The pool is opened/closed via the FastAPI lifespan in main.py.
pool: ConnectionPool = ConnectionPool(DSN, min_size=1, max_size=10, open=False)
