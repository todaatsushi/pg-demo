-- 1c. Composite Indexes
--
-- A composite (multi-column) index covers queries that filter on multiple columns.
-- Column order in the index matters — PG uses composite indexes most efficiently
-- when the query filters on a leading prefix of the indexed columns.

-- Step 1: A natural query — "all completed orders for customer 42"
-- This filters on two columns: customer_id AND status.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Step 2: Add a single-column index on customer_id
CREATE INDEX IF NOT EXISTS idx_orders_single_customer_id ON orders (customer_id);

-- PG uses the index to find customer 42's orders, then filters status in a
-- separate step (Filter). It works, but it fetches all of customer 42's orders
-- first — including pending, cancelled, refunded — only to throw most away.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Step 3: Replace with a composite index (customer_id, status)
DROP INDEX IF EXISTS idx_orders_single_customer_id;

CREATE INDEX IF NOT EXISTS idx_orders_composite_customer_status ON orders (customer_id, status);

-- Now PG navigates the B-tree to customer_id = 42 AND status = 'completed'
-- in one operation. No wasted rows fetched.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE customer_id = 42
  AND status = 'completed';

-- Step 4: Column order matters
-- Query filtering on status alone — the leading column is customer_id,
-- so PG won't use this index efficiently. Combined with status = 'completed'
-- matching ~70% of rows, a Seq Scan is the clear winner here.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'completed';

-- But a query on customer_id alone CAN use it — it matches the leading prefix.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE customer_id = 42;
