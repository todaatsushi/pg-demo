-- 2a. Nested Loop Join
--
-- How it works: for each row in the outer table, look up matching rows in
-- the inner table. Like a for loop inside a for loop.
--
-- When PG uses it: small outer result set, especially when the inner side
-- has an index for fast lookups.
--
-- Trade-off: efficient when the outer set is small and the inner lookup is
-- cheap (indexed). When the outer set grows, the repeated lookups add up.

-- Step 1: Nested loop with a small outer set
-- Outer: 100 orders (via PK index on orders.id)
-- Inner: for each order, look up the customer by PK — fast index lookup.
-- PG naturally picks nested loop here because the outer set is tiny.
EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, o.status, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.id < 100;

-- Step 2: Scale up the outer set
-- Same join, but now the outer set is 10,000 rows.
-- At this scale, PG may switch to a hash join — it's cheaper than
-- 10,000 individual index lookups. Check what the planner chose.
EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, o.status, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.id < 10000;

-- Nested loop is great when the outer set is small and the inner side is
-- indexed. As the outer set grows, PG switches to hash join or merge join
-- because the cost of repeated lookups exceeds the cost of building a
-- hash table or sorting.
