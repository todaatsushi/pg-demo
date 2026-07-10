"""
setup.py — run the 0005_app setup using the correct database user per operation.

Each section connects as the role that should own the resulting objects:

  application — creates application.orders (owner of the application schema)
  reporting   — creates the reporting views (owner of the reporting schema)
  postgres    — transfers ownership and grants read_app_data access to orders
                (superuser operations that cannot be done by the owning roles alone
                 since the grants target roles that don't own the objects yet)

Run:
    uv run python scripts/setup.py
    uv run python scripts/setup.py --pg-password mypassword
"""

import argparse

import psycopg

parser = argparse.ArgumentParser()
parser.add_argument("--host", default="localhost")
parser.add_argument("--port", type=int, default=5432)
parser.add_argument("--dbname", default="grocery_store")
parser.add_argument("--pg-password", default="postgres")
args = parser.parse_args()


def dsn(user: str, password: str) -> str:
    return f"postgresql://{user}:{password}@{args.host}:{args.port}/{args.dbname}"


print("Step 1/3: Creating application.orders as application...")
with psycopg.connect(dsn("application", "pg"), autocommit=True) as conn:
    conn.execute("""
        CREATE TABLE application.orders (
            id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            product     text NOT NULL,
            units       int NOT NULL,
            ordered_at  timestamp NOT NULL DEFAULT now(),
            store_id    bigint NOT NULL REFERENCES application.stores (id),
            staff_id    bigint NOT NULL REFERENCES application.staff (id)
        )
    """)
print("  done.")

print("Step 2/3: Creating reporting views as reporting...")
with psycopg.connect(dsn("reporting", "pg"), autocommit=True) as conn:
    conn.execute("""
        CREATE MATERIALIZED VIEW reporting.orders_by_day AS
        SELECT
            date_trunc('day', ordered_at) AS day,
            count(*) AS order_count,
            sum(units) AS total_units
        FROM application.orders
        GROUP BY date_trunc('day', ordered_at)
        ORDER BY day
    """)
    conn.execute("""
        CREATE OR REPLACE VIEW reporting.orders_by_store AS
        SELECT
            s.id AS store_id,
            s.name AS store_name,
            count(*) AS order_count,
            sum(o.units) AS total_units
        FROM application.orders o
        JOIN application.stores s ON s.id = o.store_id
        GROUP BY s.id, s.name
    """)
    conn.execute("""
        CREATE OR REPLACE VIEW reporting.orders_by_staff AS
        SELECT
            st.id AS staff_id,
            st.name AS staff_name,
            count(*) AS order_count,
            sum(o.units) AS total_units
        FROM application.orders o
        JOIN application.staff st ON st.id = o.staff_id
        GROUP BY st.id, st.name
    """)
print("  done.")

print("Step 3/3: Granting read access to orders as postgres...")
with psycopg.connect(dsn("postgres", args.pg_password), autocommit=True) as conn:
    conn.execute("GRANT SELECT ON application.orders TO read_app_data")
    conn.execute(
        "GRANT SELECT, INSERT, UPDATE, DELETE ON application.orders TO write_app_data"
    )
    conn.execute(
        "GRANT USAGE ON SEQUENCE application.orders_id_seq TO write_app_data"
    )
print("  done.")

print("\nSetup complete.")
