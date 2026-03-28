-- 1b. Partial Indexes
--
-- A partial index only indexes a subset of rows, defined by a WHERE clause.
-- Useful for low-cardinality columns where you frequently query a specific value.
--
-- product_type has only 8 distinct values across 1M rows. A full B-tree index
-- on a low-cardinality column is often ignored by the planner because too many
-- rows match — it's cheaper to just Seq Scan. A partial index solves this.

-- Context: see the distribution of product_type across orders
SELECT product_type, count(*) FROM orders GROUP BY product_type ORDER BY count DESC;

-- Step 1: Without any index
-- Seq Scan — no index exists.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE product_type = 'latte';

-- Step 2: Try a full B-tree index on product_type
CREATE INDEX IF NOT EXISTS idx_orders_full_product_type ON orders (product_type);

-- The planner may still choose a Seq Scan here. With so many rows matching
-- a single type, the index isn't selective enough to be worth the random I/O.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE product_type = 'latte';

-- Step 3: Drop the full index and create a partial index instead
DROP INDEX IF EXISTS idx_orders_full_product_type;

CREATE INDEX IF NOT EXISTS idx_orders_partial_latte ON orders (product_type)
    WHERE product_type = 'latte';

-- Now the index only contains rows where product_type = 'latte'.
-- It's much smaller, and PG will use it because the index itself is the filter.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE product_type = 'latte';

-- Step 4: Compare index sizes
-- Recreate the full index briefly to compare sizes side by side.
CREATE INDEX IF NOT EXISTS idx_orders_full_product_type ON orders (product_type);

SELECT
    pg_size_pretty(pg_relation_size('idx_orders_full_product_type')) AS full_index_size,
    pg_size_pretty(pg_relation_size('idx_orders_partial_latte')) AS partial_index_size;

DROP INDEX IF EXISTS idx_orders_full_product_type;
