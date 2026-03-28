-- 1a. B-tree Basics
--
-- B-tree is the default index type in PostgreSQL.
-- It speeds up WHERE clauses and ORDER BY on the indexed column.
--
-- Demo: query orders by customer_id, then add a B-tree index and compare.

-- Context: how many orders does customer 42 have?
SELECT count(*) AS orders_for_customer_42 FROM orders WHERE customer_id = 42;

-- Step 1: Without an index
-- This should show a Seq Scan — PG has no choice but to read every row.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 42;

-- Step 2: Create a B-tree index on customer_id
CREATE INDEX IF NOT EXISTS idx_orders_btree_customer_id ON orders (customer_id);

-- Step 3: Same query, now with the index
-- PG now uses the index (Index Scan or Bitmap Index Scan) instead of
-- reading the entire table. Much faster.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 42;
