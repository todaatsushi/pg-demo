"""
refresh_views.py - refresh all materialised views in the reporting schema.

Materialised views are snapshots - they go stale as data changes. This
script refreshes them manually. Connects as `reporting` by default, which
owns the reporting schema and its views.

Run:
    uv run python scripts/refresh_views.py
    uv run python scripts/refresh_views.py --user reporting --password pg
"""

import argparse

import psycopg

parser = argparse.ArgumentParser()
parser.add_argument("--user", default="reporting")
parser.add_argument("--password", default="pg")
args = parser.parse_args()

DSN = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

VIEWS = [
    "reporting.staff_count_by_store_mat",
    "reporting.orders_by_day",
]

with psycopg.connect(DSN, autocommit=True) as conn:
    for view in VIEWS:
        sql = f"REFRESH MATERIALIZED VIEW {view}"
        print(f"RUNNING SQL AS {args.user}:\n\n{sql}\n")
        conn.execute(sql)
        print(f"  refreshed {view}")

print("\nDone.")
