-- 3b. Long Transaction Containing ACCESS EXCLUSIVE
--
-- The sneaky category. The DDL itself is instant (metadata-only), but it's
-- bundled in the same transaction as a slow operation. The ACCESS EXCLUSIVE
-- lock is held for the entire transaction — not just the DDL.
--
-- Other examples of this pattern:
-- - ORM migrations that bundle DDL + data backfill in one transaction
-- - Migration scripts that do multiple ALTER TABLEs and UPDATEs together
-- - Any tool that wraps migrations in BEGIN/COMMIT automatically

-- === SESSION 1 ===
-- The ALTER is instant (nullable column, no default rewrite).
-- But the UPDATE rewrites every row — and the lock is held the whole time.
BEGIN;
ALTER TABLE orders ADD COLUMN customer_name text;
UPDATE orders SET customer_name = c.name
    FROM customers c WHERE orders.customer_id = c.id;
COMMIT;

-- === SESSION 2 ===
-- While session 1 is running, try a simple read.
-- This will hang — the ACCESS EXCLUSIVE lock from the ALTER is still held
-- because the transaction hasn't committed yet.
SELECT * FROM orders LIMIT 1;
