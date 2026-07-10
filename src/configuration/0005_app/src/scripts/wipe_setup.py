"""
wipe_setup.py — reverse the 0005_app setup using the correct user per operation.

Each section connects as the role that owns the objects being dropped:

  reporting   — drops the reporting views (owner of reporting schema)
  application — drops application.orders (owner of application schema)

Run:
    uv run python scripts/wipe_setup.py
"""

import argparse

import psycopg

parser = argparse.ArgumentParser()
parser.add_argument("--host", default="localhost")
parser.add_argument("--port", type=int, default=5432)
parser.add_argument("--dbname", default="grocery_store")
args = parser.parse_args()


def dsn(user: str, password: str) -> str:
    return f"postgresql://{user}:{password}@{args.host}:{args.port}/{args.dbname}"


print("Step 1/2: Dropping reporting views as reporting...")
with psycopg.connect(dsn("reporting", "pg"), autocommit=True) as conn:
    conn.execute("DROP MATERIALIZED VIEW IF EXISTS reporting.orders_by_day")
    conn.execute("DROP VIEW IF EXISTS reporting.orders_by_staff")
    conn.execute("DROP VIEW IF EXISTS reporting.orders_by_store")
print("  done.")

print("Step 2/2: Dropping application.orders as application...")
with psycopg.connect(dsn("application", "pg"), autocommit=True) as conn:
    conn.execute("DROP TABLE IF EXISTS application.orders")
print("  done.")

print("\nWipe complete.")
