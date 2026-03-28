-- 3e. lock_timeout
--
-- lock_timeout is a safety net. Instead of queuing indefinitely for a lock,
-- the statement fails fast if it can't acquire the lock within the timeout.
-- This prevents the cascading queue effect from 3d.

-- === SESSION 1 ===
-- Open a transaction and hold ACCESS SHARE.
BEGIN;
SELECT count(*) FROM orders;
-- (don't commit yet)

-- === SESSION 2 ===
-- Set lock_timeout before running the migration.
-- The DDL will fail after 3 seconds instead of waiting forever.
SET lock_timeout = '3s';
BEGIN;
ALTER TABLE orders ADD COLUMN timeout_col text;
COMMIT;
-- After 3 seconds: "ERROR: canceling statement due to lock timeout"
-- The transaction is aborted — no lock was acquired, no cascade.

-- === SESSION 3 ===
-- Unlike 3d, subsequent queries are unaffected.
-- There's no queued DDL blocking the lock queue.
SELECT * FROM orders LIMIT 1;
-- This works immediately.

-- === SESSION 1 ===
COMMIT;

-- Reset lock_timeout to default (no timeout).
RESET lock_timeout;
