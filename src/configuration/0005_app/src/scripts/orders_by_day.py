"""
orders_by_day.py — query reporting.orders_by_day and print results to stdout.

This is a materialised view — results reflect the last REFRESH, not live data.
Returns empty if the orders table has not been seeded.

Run:
    uv run python scripts/orders_by_day.py
    uv run python scripts/orders_by_day.py --user reporting --password pg
    uv run python scripts/orders_by_day.py --user developer_ro --password pg
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
        "SELECT day, order_count, total_units "
        "FROM reporting.orders_by_day "
        "ORDER BY day"
    ).fetchall()

if not rows:
    print("No data — orders table is empty or view has not been refreshed.")
else:
    print(f"{'Day':<14} {'Orders':>8} {'Units':>8}")
    print("-" * 34)
    for row in rows:
        print(f"{str(row['day']):<14} {row['order_count']:>8} {row['total_units']:>8}")
