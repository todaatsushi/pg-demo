-- 1b. Partial Indexes
--
-- A partial index only indexes a subset of rows, defined by a WHERE clause.
-- Useful when you frequently query a specific combination of values on a
-- large table — the index is smaller and more targeted than a full index.

-- Context: see the distribution of product_type and status across orders
SELECT product_type, status, count(*)
FROM orders
GROUP BY product_type, status
ORDER BY product_type, count DESC;

-- Step 1: Without any index
-- Seq Scan — no index exists.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE product_type = 'latte' AND status = 'pending';

-- Step 2: Try a full B-tree index on (product_type, status)
CREATE INDEX IF NOT EXISTS idx_orders_full_type_status ON orders (product_type, status);

-- The planner may use this index, but it covers ALL product_type/status
-- combinations — most of which we never query. The index is large.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE product_type = 'latte' AND status = 'pending';

-- Step 3: Drop the full index and create a partial index instead
DROP INDEX IF EXISTS idx_orders_full_type_status;

CREATE INDEX IF NOT EXISTS idx_orders_partial_latte_pending ON orders (id)
    WHERE product_type = 'latte' AND status = 'pending';

-- Now the index only contains the ~1% of rows matching both conditions.
-- It's much smaller and highly selective.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE product_type = 'latte' AND status = 'pending';

-- Step 4: Compare index sizes
-- Recreate the full index briefly to compare sizes side by side.
CREATE INDEX IF NOT EXISTS idx_orders_full_type_status ON orders (product_type, status);

SELECT
    pg_size_pretty(pg_relation_size('idx_orders_full_type_status')) AS full_index_size,
    pg_size_pretty(pg_relation_size('idx_orders_partial_latte_pending')) AS partial_index_size;

DROP INDEX IF EXISTS idx_orders_full_type_status;
