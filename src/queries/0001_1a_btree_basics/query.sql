-- 1a. B-tree Basics
--
-- B-tree is the default index type in PostgreSQL.
-- It speeds up WHERE clauses and ORDER BY on the indexed column.
--
-- Demo: query orders by customer_id, then add a B-tree index and compare.
--
-- Note: when comparing EXPLAIN ANALYZE output, focus on the plan structure
-- (node types, row estimates, buffer counts) rather than raw timings.
-- Timings vary between runs depending on cache state and planner statistics.

-- Context: how many orders does customer 42 have?
SELECT count(*) AS orders_for_customer_42 FROM orders WHERE customer_id = 42;

-- Step 1: Without an index
-- This should show a Seq Scan — PG has no choice but to read every row.
EXPLAIN ANALYZE
SELECT id FROM orders WHERE customer_id = 42;

-- Step 2: Create a B-tree index on customer_id
CREATE INDEX IF NOT EXISTS idx_orders_btree_customer_id ON orders (customer_id);

-- Step 3: Same query, now with the index
-- PG now uses the index (Index Scan or Bitmap Index Scan) instead of
-- reading the entire table. Much faster.
EXPLAIN ANALYZE
SELECT id FROM orders WHERE customer_id = 42;

-- Step 4: Additional filters benefit from the index too
-- status isn't in the index, but that's fine — the index on customer_id
-- already narrows 10M rows down to a handful. PG fetches those few rows
-- from the heap and applies the status filter in-memory for free.
EXPLAIN ANALYZE
SELECT id FROM orders WHERE customer_id = 42 AND status = 'completed';

-- Step 5: Indexes aren't magic — selectivity matters
-- A narrow range is selective enough that PG uses the index.
EXPLAIN ANALYZE
SELECT id FROM orders WHERE customer_id BETWEEN 42 AND 100;

-- Step 5: Widen the range — PG abandons the index
-- Same column, same index, but the range is so wide that PG decides a
-- Seq Scan is cheaper than bouncing through the index for most of the table.
EXPLAIN ANALYZE
SELECT id FROM orders WHERE customer_id > 42;

-- customer_id is a FK - it's very common to filter / query on them. This is why they
-- should always be indexed!
