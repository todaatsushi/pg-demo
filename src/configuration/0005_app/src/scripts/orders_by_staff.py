"""
orders_by_staff.py - query reporting.orders_by_staff and print results to stdout.

This is a regular view - results are always current.
Returns empty if the orders table has not been seeded.

Run:
    uv run python scripts/orders_by_staff.py
    uv run python scripts/orders_by_staff.py --user reporting --password pg
    uv run python scripts/orders_by_staff.py --user developer_ro --password pg
"""

import argparse

import psycopg
from psycopg.rows import dict_row

parser = argparse.ArgumentParser()
parser.add_argument("--user", default="reporting")
parser.add_argument("--password", default="pg")
args = parser.parse_args()

DSN = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

conn = psycopg.connect(DSN, row_factory=dict_row)
with conn:
    rows = conn.execute(
        "SELECT staff_id, staff_name, order_count, total_units "
        "FROM reporting.orders_by_staff "
        "ORDER BY staff_id"
    ).fetchall()

if not rows:
    print("No data - orders table is empty.")
else:
    print(f"{'ID':<6} {'Staff':<30} {'Orders':>8} {'Units':>8}")
    print("-" * 56)
    for row in rows:
        print(
            f"{row['staff_id']:<6} {row['staff_name']:<30} "
            f"{row['order_count']:>8} {row['total_units']:>8}"
        )
