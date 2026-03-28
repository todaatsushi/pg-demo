-- 3a. Long Operation + ACCESS EXCLUSIVE
--
-- The most dangerous category of migration. The DDL itself takes a long time
-- (rewriting every row) and holds an ACCESS EXCLUSIVE lock — blocking ALL
-- queries, including SELECTs, for the entire duration.
--
-- Other examples of this pattern:
-- - Adding a stored generated column
-- - Changing a column type with USING expression
-- - Adding NOT NULL to an existing nullable column (scans every row to validate)

-- === SESSION 1 ===
-- This rewrites every row to convert timestamp → timestamptz.
-- On 1M rows this takes a noticeable amount of time.
-- Leave it running and switch to session 2.
BEGIN;
ALTER TABLE orders ALTER COLUMN ordered_at TYPE timestamptz;
COMMIT;

-- === SESSION 2 ===
-- While the ALTER is running, try a simple read.
-- This will hang — ACCESS EXCLUSIVE blocks everything, even SELECTs.
SELECT * FROM orders LIMIT 1;
