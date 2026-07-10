"""
seed_orders.py — insert random orders concurrently to demo the application user
writing at scale.

Each worker inserts total/workers orders over roughly `duration` seconds, with
±50% jitter per insert interval. Store and staff IDs are fetched once at start
and sampled randomly per order.

Connects as `application` by default — the owner of the `application` schema
with full write access to `application.orders`.

Run:
    uv run python scripts/seed_orders.py
    uv run python scripts/seed_orders.py --total 1000 --duration 30 --workers 10
    uv run python scripts/seed_orders.py --total 500 --duration 60 \\
        --workers 5 --progress-every 50
"""

import argparse
import random
import threading
import time
from concurrent.futures import FIRST_EXCEPTION, ThreadPoolExecutor, wait
from datetime import datetime, timedelta, timezone
from typing import Any

import psycopg
from psycopg_pool import ConnectionPool

PRODUCTS = [
    "English Breakfast Tea",
    "Chamomile Tea",
    "Green Tea",
    "Matcha Latte",
    "Espresso",
    "Double Espresso",
    "Americano",
    "Cappuccino",
    "Vanilla Latte",
    "Oat Milk Latte",
    "Flat White",
    "Mocha",
    "Hazelnut Mocha",
    "Iced Coffee",
    "Cold Brew",
]


def worker(
    pool: Any,
    count: int,
    delay: float,
    store_ids: list[int],
    staff_ids: list[int],
    counter: list[int],
    lock: threading.Lock,
    progress_every: int,
    total: int,
    start: float,
    random_dt: bool,
    dt_range_days: int,
) -> None:
    for _ in range(count):
        product = random.choice(PRODUCTS)
        units = random.randint(1, 5)
        store_id = random.choice(store_ids)
        staff_id = random.choice(staff_ids)

        if random_dt:
            ordered_at = datetime.now(timezone.utc) - timedelta(
                seconds=random.randint(0, dt_range_days * 86400)
            )
            with pool.connection() as conn:
                conn.execute(
                    "INSERT INTO application.orders "
                    "(product, units, store_id, staff_id, ordered_at) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (product, units, store_id, staff_id, ordered_at),
                )
        else:
            with pool.connection() as conn:
                conn.execute(
                    "INSERT INTO application.orders "
                    "(product, units, store_id, staff_id) "
                    "VALUES (%s, %s, %s, %s)",
                    (product, units, store_id, staff_id),
                )

        with lock:
            counter[0] += 1
            if counter[0] % progress_every == 0:
                elapsed = time.time() - start
                rate = counter[0] / elapsed if elapsed > 0 else 0
                print(
                    f"[{counter[0]:>6} / {total}]  "
                    f"{elapsed:>6.1f}s elapsed  ~{rate:.1f} orders/sec"
                )

        jitter = random.uniform(-delay / 2, delay / 2)
        time.sleep(max(0.0, delay + jitter))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--total", type=int, default=1000)
    parser.add_argument("--duration", type=float, default=30.0)
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--user", default="application")
    parser.add_argument("--password", default="pg")
    parser.add_argument("--progress-every", type=int, default=100)
    parser.add_argument(
        "--true-dt",
        action="store_true",
        help="Use real current timestamps instead of random historical ones",
    )
    parser.add_argument(
        "--dt-range-days",
        type=int,
        default=365,
        help="How far back (in days) random timestamps can go (default 365)",
    )
    args = parser.parse_args()

    dsn = f"postgresql://{args.user}:{args.password}@localhost:5432/grocery_store"

    print("Fetching store and staff IDs...")
    with psycopg.connect(dsn) as conn:
        store_ids = [
            r[0] for r in conn.execute("SELECT id FROM application.stores").fetchall()
        ]
        staff_ids = [
            r[0] for r in conn.execute("SELECT id FROM application.staff").fetchall()
        ]

    if not store_ids:
        raise SystemExit("No stores found — run 0002_data/run.sql first.")
    if not staff_ids:
        raise SystemExit("No staff found — run 0002_data/run.sql first.")

    base_count, remainder = divmod(args.total, args.workers)
    counts = [base_count + (1 if i < remainder else 0) for i in range(args.workers)]
    delay = args.duration / base_count if base_count > 0 else 0.0

    dt_mode = (
        "true timestamps"
        if args.true_dt
        else f"random timestamps up to {args.dt_range_days} days back"
    )
    print(
        f"Seeding {args.total} orders across {args.workers} workers "
        f"over ~{args.duration}s (delay={delay:.3f}s ±50% jitter per insert) "
        f"{dt_mode}"
    )

    pool = ConnectionPool(dsn, min_size=args.workers, max_size=args.workers, open=True)
    counter: list[int] = [0]
    lock = threading.Lock()
    start = time.time()

    try:
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            futures = [
                executor.submit(
                    worker,
                    pool,
                    counts[i],
                    delay,
                    store_ids,
                    staff_ids,
                    counter,
                    lock,
                    args.progress_every,
                    args.total,
                    start,
                    not args.true_dt,
                    args.dt_range_days,
                )
                for i in range(args.workers)
            ]
            done, _ = wait(futures, return_when=FIRST_EXCEPTION)
            for f in done:
                f.result()
    finally:
        pool.close()

    elapsed = time.time() - start
    rate = counter[0] / elapsed if elapsed > 0 else 0
    print(f"\nDone. {counter[0]} orders inserted in {elapsed:.1f}s (~{rate:.1f}/sec)")


if __name__ == "__main__":
    main()
