-- 1d. Covering Indexes (INCLUDE)
--
-- When PG uses an index, it finds matching row pointers then visits the heap
-- (table) to fetch the actual row data. A "covering" index avoids this heap
-- lookup by storing all the columns the query needs inside the index itself.
--
-- If every column in the SELECT, WHERE, and ORDER BY is in the index, PG can
-- answer the query entirely from the index — an Index Only Scan.

-- Ensure the visibility map is up to date — Index Only Scans need this
-- to know which heap pages are all-visible (no recent changes).
-- Without VACUUM after a bulk load, PG may still visit the heap.
VACUUM orders;

-- Prerequisite: composite index on (customer_id, status)
CREATE INDEX IF NOT EXISTS idx_orders_covering_customer_status ON orders (customer_id, status);

-- Step 1: Index Only Scan with indexed columns only
-- If we SELECT only (customer_id, status), PG doesn't need the heap at all.
EXPLAIN ANALYZE
SELECT customer_id, status FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Step 2: Add a column not in the index
-- Now we also want ordered_at. PG has to visit the heap to get it,
-- even though it found the rows via the index.
EXPLAIN ANALYZE
SELECT customer_id, status, ordered_at FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Step 3: Use INCLUDE to cover the extra column
-- INCLUDE stores ordered_at as payload in the index — not sorted or searchable,
-- just available for reading. The index stays small because the B-tree structure
-- only sorts on (customer_id, status).
DROP INDEX IF EXISTS idx_orders_covering_customer_status;

CREATE INDEX IF NOT EXISTS idx_orders_covering_customer_status_incl ON orders (customer_id, status)
    INCLUDE (ordered_at);

-- Same query — now it's an Index Only Scan. No heap access needed.
EXPLAIN ANALYZE
SELECT customer_id, status, ordered_at FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Note: INCLUDE columns are not part of the B-tree search key, so the index
-- cannot accelerate filtering or sorting on them. They can appear in SQL
-- WHERE/ORDER BY clauses, but PG won't use the index for those conditions.
