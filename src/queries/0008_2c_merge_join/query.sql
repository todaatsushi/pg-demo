-- 2c. Merge Join
--
-- How it works: both sides are sorted on the join key, then PG walks through
-- them in lockstep — like merging two sorted lists.
--
-- When PG uses it: both sides are already sorted (via index) or very large datasets.
-- Trade-off: the merge itself is fast, but sorting is expensive if there's no index.
-- PG often prefers hash join unless the data is already in order.

-- We disable hash join and nested loop so PG is forced to use merge join.
-- We're being explicit about this — in practice PG picks merge join on its own
-- when the conditions are right (both sides pre-sorted via indexes).
SET enable_hashjoin = off;
SET enable_nestloop = off;

-- Step 1: Merge join without indexes on the join key
-- PG has to sort both sides before it can merge. Look for Sort nodes in the plan.
-- BUFFERS shows whether the sort spilled to disk.
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.ordered_at, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id;

-- Step 2: Add an index on orders.customer_id
-- customers.id already has a PK index. PG now has the option to read both
-- sides in order from the indexes, potentially eliminating the Sort steps.
CREATE INDEX IF NOT EXISTS idx_orders_merge_join_customer_id ON orders (customer_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.ordered_at, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id;

-- Step 3: Re-enable hash join and compare
-- PG may still prefer hash join even with indexes on both sides —
-- which illustrates that merge join has a narrow sweet spot.
RESET enable_hashjoin;
RESET enable_nestloop;

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.ordered_at, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id;

-- Summary:
-- Merge join is efficient when both sides are pre-sorted. But if PG has to
-- sort first, hash join usually wins. You'll most often see merge join on
-- very large datasets where indexes already provide the sort order.
