-- 1c. Partial Indexes
--
-- A partial index only indexes a subset of rows, defined by a WHERE clause.
-- Useful when you frequently query a specific subset of a large table —
-- the index is smaller and more targeted than a full index.
--
-- Scenario: a workflow that processes pending orders. The dashboard constantly
-- queries pending orders, often filtered by product type (e.g. pending lattes).

-- Context: see the distribution of product_type and status across orders
SELECT product_type, status, count(*)
FROM orders
WHERE status = 'pending'
GROUP BY product_type, status
ORDER BY product_type, count DESC;

-- Step 1: Without any index
-- Seq Scan — no index exists.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'pending' AND product_type = 'latte';

-- Step 2: Try a B-tree index on status
-- Intuition says this should help — but status has very few distinct values
-- (pending, completed, cancelled, refunded). Most rows match 'pending' or
-- 'completed', so the index isn't selective enough. PG may still Seq Scan.
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'pending' AND product_type = 'latte';

DROP INDEX IF EXISTS idx_orders_status;

-- Step 3: Choosing what to index — access patterns, not just the data model
-- Before adding more indexes, look at what you're actually querying and
-- what the data looks like.

-- How many pending orders are there?
SELECT count(*) AS pending_orders FROM orders WHERE status = 'pending';

-- How many distinct product_type/status combinations exist?
SELECT product_type, status, count(*)
FROM orders
WHERE status = 'pending'
GROUP BY product_type, status
ORDER BY product_type, count DESC;

-- Only a small set of combinations across millions of rows. Each combination still
-- matches a large slice of the table — that's low cardinality.
-- A single-column index on either column leaves PG with too many rows
-- to fetch, which is why Step 2 didn't help.

-- Step 4: Try a composite B-tree index on (product_type, status)
-- We know there is a small set of combos, let's try a composite index!
CREATE INDEX IF NOT EXISTS idx_orders_full_type_status ON orders (product_type, status);

-- The planner may use this index, but it covers ALL product_type/status
-- combinations — most of which we never query. The index is large and index scans don't
-- speed it up drastically
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'pending' AND product_type = 'latte';

-- Side note: The index narrows by both columns, but the result set is
-- still large — and each matching row needs a heap fetch. Indexes help PG
-- find rows faster, but they can't skip reading them. For heavy aggregate
-- or wide-filter queries, a row-oriented database like PostgreSQL will
-- always hit a ceiling. That's why reporting and analytics workloads often
-- use different stores.

-- Step 5: Drop the full index and create a partial index instead
DROP INDEX IF EXISTS idx_orders_full_type_status;

CREATE INDEX IF NOT EXISTS idx_orders_partial_latte_pending ON orders (id) WHERE status = 'pending';

-- The index only contains the ~15% of rows that are pending, indexed by id.
-- PG filters product_type at query time on this much smaller set.
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'pending' and product_type = 'latte';

-- Step 6: Compare index sizes
-- Recreate the full index briefly to compare sizes side by side.
CREATE INDEX IF NOT EXISTS idx_orders_full_type_status ON orders (product_type, status);

SELECT
    pg_size_pretty(pg_relation_size('idx_orders_full_type_status')) AS full_index_size,
    pg_size_pretty(pg_relation_size('idx_orders_partial_latte_pending')) AS partial_index_size;

DROP INDEX IF EXISTS idx_orders_full_type_status;
