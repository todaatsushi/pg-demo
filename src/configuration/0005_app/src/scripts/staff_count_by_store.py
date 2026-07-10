"""
staff_count_by_store.py — query reporting.staff_count_by_store_mat and print
results to stdout.

This is a materialised view — results reflect the last REFRESH, not live data.

Run:
    uv run python scripts/staff_count_by_store.py
    uv run python scripts/staff_count_by_store.py --user reporting --password pg
    uv run python scripts/staff_count_by_store.py --user developer_ro --password pg
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
        "SELECT store_id, store_name, staff_count "
        "FROM reporting.staff_count_by_store_mat "
        "ORDER BY store_id"
    ).fetchall()

print(f"{'ID':<6} {'Store':<30} {'Staff'}")
print("-" * 45)
for row in rows:
    print(f"{row['store_id']:<6} {row['store_name']:<30} {row['staff_count']}")
