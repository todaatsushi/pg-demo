"""
ddl.py — run DDL migrations as the `application` login user.

`application` owns the `application` schema and therefore has full DDL
rights on it — CREATE, ALTER, DROP on any object within it. Running as
any other user (e.g. `developer_ro`) will fail with:
  ERROR: must be owner of schema application

Run forward migration:
    uv run python scripts/ddl.py
    uv run python scripts/ddl.py --user application --password CRUD

Run reverse (drop reviews table):
    uv run python scripts/ddl.py --reverse

Demo: run as wrong user to see permission denied:
    uv run python scripts/ddl.py --user developer_ro --password pg
"""

import argparse

import psycopg

parser = argparse.ArgumentParser()
parser.add_argument("--user", default="application")
parser.add_argument("--password", default="CRUD")
parser.add_argument("--reverse", action="store_true")
args = parser.parse_args()

FORWARD = """
BEGIN;
CREATE TABLE application.reviews (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);
COMMIT;
"""

REVERSE = """
BEGIN;
DROP TABLE application.reviews;
COMMIT;
"""

sql = REVERSE if args.reverse else FORWARD
label = "reverse" if args.reverse else "forward"

DSN = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

with psycopg.connect(DSN, autocommit=True) as conn:
    conn.execute(sql)

print(f"DDL {label} migration applied successfully.")
