"""
long_running_transactions.py - query pg_stat_activity for transactions that
have been running longer than a given threshold and print results to stdout.

Connects as `performance_monitoring` by default, which has the `pg_monitor`
role granting access to pg_stat_activity.

Run:
    uv run python scripts/long_running_transactions.py
    uv run python scripts/long_running_transactions.py \\
        --user performance_monitoring --password pg
    uv run python scripts/long_running_transactions.py --min-seconds 10
"""

import argparse

import psycopg
from psycopg.rows import dict_row

parser = argparse.ArgumentParser()
parser.add_argument("--user", default="performance_monitoring")
parser.add_argument("--password", default="pg")
parser.add_argument("--min-seconds", type=int, default=5)
args = parser.parse_args()

DSN = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

SQL = f"""
SELECT
    usename,
    xact_start,
    now() - xact_start AS duration,
    query
FROM pg_stat_activity
WHERE state != 'idle'
  AND xact_start IS NOT NULL
  AND now() - xact_start > {args.min_seconds} * interval '1 second'
ORDER BY duration DESC
""".strip()

print(f"RUNNING SQL AS {args.user}:\n\n{SQL}\n")
conn = psycopg.connect(DSN, row_factory=dict_row)
with conn:
    rows = conn.execute(
        """
        SELECT
            usename,
            xact_start,
            now() - xact_start AS duration,
            query
        FROM pg_stat_activity
        WHERE state != 'idle'
          AND xact_start IS NOT NULL
          AND now() - xact_start > %s * interval '1 second'
        ORDER BY duration DESC
        """,
        (args.min_seconds,),
    ).fetchall()

if not rows:
    print(f"No transactions running longer than {args.min_seconds}s.")
else:
    print(f"{'User':<25} {'Started':<30} {'Duration':<20} Query")
    print("-" * 120)
    for row in rows:
        query_preview = (row["query"] or "").replace("\n", " ")[:60]
        print(
            f"{row['usename']:<25} "
            f"{str(row['xact_start']):<30} "
            f"{str(row['duration']):<20} "
            f"{query_preview}"
        )
