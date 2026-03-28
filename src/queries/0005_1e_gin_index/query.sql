-- 1e. GIN Index (non-B-tree)
--
-- B-tree is not the only index type. GIN (Generalized Inverted Index) is
-- designed for values that contain multiple elements — arrays, full-text
-- search, JSONB, etc.
--
-- orders.tags is a text[] column denormalized from products (e.g. {'vegan', 'organic'}).
-- We want to find orders that contain specific tags.

-- Context: see what tags look like in the data and how common each tag is
SELECT tags, count(*) FROM orders WHERE tags IS NOT NULL GROUP BY tags ORDER BY count DESC LIMIT 10;
SELECT unnest(tags) AS tag, count(*) FROM orders GROUP BY tag ORDER BY count;

-- Step 1: No index
-- Seq Scan — PG checks every row.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE tags @> ARRAY['vegan', 'organic', 'fair trade'];

-- Step 2: Try a B-tree index on tags
-- B-tree indexes on arrays support standard comparison operators (<, =, >)
-- but only compare arrays as whole values. They cannot help with containment
-- operators like @> that inspect individual elements.
CREATE INDEX IF NOT EXISTS idx_orders_tags_btree ON orders (tags);

-- Still a Seq Scan — the B-tree can't handle @>.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE tags @> ARRAY['vegan', 'organic', 'fair trade'];

-- Step 3: Replace with a GIN index
DROP INDEX IF EXISTS idx_orders_tags_btree;

CREATE INDEX IF NOT EXISTS idx_orders_tags_gin ON orders USING gin (tags);

-- Now PG uses a Bitmap Index Scan on the GIN index.
-- GIN indexes individual array elements, so it can efficiently find all
-- rows where the array contains all three tags.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE tags @> ARRAY['vegan', 'organic', 'fair trade'];

-- GIN handles even more specific queries — the more tags we filter on,
-- the fewer rows match, and the bigger the speedup over a Seq Scan.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE tags @> ARRAY['vegan', 'organic', 'fair trade', 'offer'];
