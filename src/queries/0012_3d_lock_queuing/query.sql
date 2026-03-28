-- 3d. Lock Queuing
--
-- Even a fast DDL (instant metadata change) acquires ACCESS EXCLUSIVE briefly.
-- If a long-running query is already holding ACCESS SHARE, the DDL queues.
-- And everything that comes after the DDL queues behind it too — including
-- reads that would normally be fine alongside the original query.
--
-- This is how a "safe, instant" migration can take down an entire table.

-- === SESSION 1 ===
-- Open a transaction and run a query. Don't commit — this holds ACCESS SHARE.
BEGIN;
SELECT count(*) FROM orders;
-- (don't commit yet — leave this transaction open)

-- === SESSION 2 ===
-- Run a fast DDL inside a transaction (as most migration tools do).
-- It needs ACCESS EXCLUSIVE, but session 1 holds ACCESS SHARE.
-- The DDL queues, waiting for session 1 to finish.
BEGIN;
ALTER TABLE orders ADD COLUMN queued_col text;
COMMIT;

-- === SESSION 3 ===
-- Try a simple read. Normally this would work fine alongside session 1's SELECT.
-- But the queued DDL in session 2 is ahead of us in the lock queue — and it
-- needs ACCESS EXCLUSIVE, which conflicts with our ACCESS SHARE request.
-- So we queue behind the DDL, which is queued behind session 1.
SELECT * FROM orders LIMIT 1;
-- This hangs too. The cascade: session 1 → DDL → session 3, all waiting.

-- === SESSION 1 ===
-- Commit to release the ACCESS SHARE lock.
-- The DDL in session 2 now acquires ACCESS EXCLUSIVE, runs instantly, and releases.
-- Then session 3's SELECT finally runs.
COMMIT;
