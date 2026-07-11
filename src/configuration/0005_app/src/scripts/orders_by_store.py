"""
orders_by_store.py - query reporting.orders_by_store and print results to stdout.

This is a regular view - results are always current.
Returns empty if the orders table has not been seeded.

Run:
    uv run python scripts/orders_by_store.py
    uv run python scripts/orders_by_store.py --user reporting --password pg
    uv run python scripts/orders_by_store.py --user developer_ro --password pg
"""

import argparse

import psycopg
from psycopg.rows import dict_row

parser = argparse.ArgumentParser()
parser.add_argument("--user", default="reporting")
parser.add_argument("--password", default="pg")
args = parser.parse_args()

DSN = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

SQL = (
    "SELECT store_id, store_name, order_count, total_units "
    "FROM reporting.orders_by_store "
    "ORDER BY store_id"
)

print(f"RUNNING SQL AS {args.user}:\n\n{SQL}\n")
conn = psycopg.connect(DSN, row_factory=dict_row)
with conn:
    rows = conn.execute(SQL).fetchall()

if not rows:
    print("No data - orders table is empty.")
else:
    print(f"{'ID':<6} {'Store':<30} {'Orders':>8} {'Units':>8}")
    print("-" * 56)
    for row in rows:
        print(
            f"{row['store_id']:<6} {row['store_name']:<30} "
            f"{row['order_count']:>8} {row['total_units']:>8}"
        )
