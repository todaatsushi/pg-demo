-- 3c. Long Operation + Weaker Lock (SHARE)
--
-- Not all dangerous locks are ACCESS EXCLUSIVE. CREATE INDEX takes a SHARE
-- lock — reads continue fine, but writes are blocked for the duration.
-- On a large table, the index build takes long enough that writers pile up.
--
-- Other examples of this pattern:
-- - Any non-CONCURRENTLY index build
--
-- Wrapped in BEGIN/COMMIT as most migration tools do automatically.

-- === SESSION 1 ===
-- This takes a SHARE lock while building the index. Slow on 1M rows.
BEGIN;
CREATE INDEX idx_orders_lock_demo ON orders (ordered_at);
COMMIT;

-- === SESSION 2 (while session 1 is running) ===
-- Reads are fine — SHARE allows SELECT.
SELECT * FROM orders LIMIT 1;

-- Writes are blocked — SHARE conflicts with ROW EXCLUSIVE (needed for INSERT/UPDATE).
INSERT INTO orders (ordered_at, status, quantity, product_type, product_id, customer_id, staff_id)
VALUES (now(), 'pending', 1, 'latte', 1, 1, 1);

-- === SAFE ALTERNATIVE: CREATE INDEX CONCURRENTLY ===
-- Uses SHARE UPDATE EXCLUSIVE — allows both reads and writes during the build.
-- But it CANNOT run inside a transaction.
DROP INDEX IF EXISTS idx_orders_lock_demo;
CREATE INDEX CONCURRENTLY idx_orders_lock_demo_concurrent ON orders (ordered_at);

-- === BUT: CONCURRENTLY has its own catch ===
-- It builds in two phases:
--   Phase 1: Scans the table and builds the index. Reads/writes continue normally.
--   Phase 2: Does a second pass to pick up rows changed during phase 1. To do this
--            safely, it must wait for ALL transactions that started before the index
--            build to finish. If any transaction is still open — even an idle one —
--            the index build stalls waiting for it.
--
-- Demo: open a transaction in session 1, then try CONCURRENTLY in session 2.

-- Session 1: open a transaction and leave it idle
BEGIN;
SELECT count(*) FROM orders;
-- (don't commit yet — leave this transaction open)

-- Session 2: start the concurrent index build
DROP INDEX IF EXISTS idx_orders_lock_demo_concurrent;
CREATE INDEX CONCURRENTLY idx_orders_lock_demo_concurrent ON orders (ordered_at);
-- This will stall in phase 2, waiting for session 1's transaction to finish.

-- Session 1: commit to unblock the index build
COMMIT;
-- The index build in session 2 now completes.

-- There's no hard and fast rule. On a smaller or newer table with low traffic,
-- a regular CREATE INDEX (full SHARE lock) might actually be preferable — it's
-- simpler, faster, and doesn't have the two-phase waiting problem. CONCURRENTLY
-- is for when you can't afford to block writes on a busy table.
