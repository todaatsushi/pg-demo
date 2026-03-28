-- 2a. Nested Loop Join
--
-- How it works: for each row in the outer table, scan the inner table for matches.
-- Like a for loop inside a for loop.
--
-- When PG uses it: small outer result set, especially when the inner side has an index.
-- Trade-off: fine for small lookups, terrible at scale without an index on the inner side.

-- Context: pick a real customer and see how many orders they have
SELECT c.id, c.name, count(o.id) AS order_count
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 42
GROUP BY c.id, c.name;

-- Step 1: Nested loop without an index on the inner side
-- PG finds the one matching customer, then for that customer it has to
-- scan the entire orders table to find their orders. The inner side
-- has no fast path — every loop iteration is a full scan.
EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, o.status, c.name
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 42;

-- Step 2: Add an index on orders.customer_id
CREATE INDEX IF NOT EXISTS idx_orders_nested_loop_customer_id ON orders (customer_id);

-- Same query — PG still uses a nested loop, but now each iteration
-- does an index lookup instead of a full scan. Fast.
EXPLAIN ANALYZE
SELECT o.id, o.ordered_at, o.status, c.name
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.id = 42;

-- The nested loop itself isn't the problem — it's what happens on
-- the inner side that matters. Without an index, each iteration is
-- expensive. With an index, each iteration is a quick lookup.
