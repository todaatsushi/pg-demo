-- 2b. Hash Join
--
-- How it works: PG builds a hash table from the smaller table, then scans the
-- larger table and probes the hash table for matches.
--
-- When PG uses it: larger joins where there's no useful index on the join column.
-- Trade-off: needs enough memory (work_mem) to hold the hash table. If the hash
-- table doesn't fit in memory, it spills to disk in multiple batches — much slower.

-- Context: check current work_mem
SHOW work_mem;

-- Step 1: Hash join under normal conditions
-- Join 1M orders to 60 products with no index on orders.product_id.
-- PG hashes the small products table and probes it for each order.
EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, p.name, p.type
FROM orders o
JOIN products p ON p.id = o.product_id;

-- Step 2: Reduce work_mem to force the hash table to spill to disk
-- Even though the products table is small, at 1kB PG can't fit the hash
-- table in memory — it splits into multiple batches and writes temp files.
-- Look for "Batches: N" (where N > 1) in the output.
SET work_mem = '1kB';

EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, p.name, p.type
FROM orders o
JOIN products p ON p.id = o.product_id;

-- Step 3: Reset work_mem
RESET work_mem;

-- The hash join itself is efficient — the problem is when memory is too
-- tight and it spills to disk. In production this shows up as slow queries
-- when work_mem is undersized for the join.
