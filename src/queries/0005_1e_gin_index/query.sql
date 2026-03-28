-- 1e. GIN Index (non-B-tree)
--
-- B-tree is not the only index type. GIN (Generalized Inverted Index) is
-- designed for values that contain multiple elements — arrays, full-text
-- search, JSONB, etc.
--
-- products.tags is a text[] column (e.g. {'vegan', 'organic', 'offer'}).
-- We want to find products that contain a specific tag.

-- Context: see what tags look like in the data
SELECT name, tags FROM products LIMIT 10;

-- Step 1: No index
-- Seq Scan — PG checks every row.
EXPLAIN ANALYZE
SELECT * FROM products WHERE tags @> ARRAY['vegan'];

-- Step 2: Try a B-tree index on tags
-- B-tree indexes on arrays only support equality (=) on the whole array.
-- They cannot help with containment operators like @> (contains).
CREATE INDEX IF NOT EXISTS idx_products_tags_btree ON products (tags);

-- Still a Seq Scan — the B-tree can't handle @>.
EXPLAIN ANALYZE
SELECT * FROM products WHERE tags @> ARRAY['vegan'];

-- Step 3: Replace with a GIN index
DROP INDEX IF EXISTS idx_products_tags_btree;

CREATE INDEX IF NOT EXISTS idx_products_tags_gin ON products USING gin (tags);

-- Now PG uses a Bitmap Index Scan on the GIN index.
-- GIN indexes individual array elements, so it can efficiently find all
-- rows where the array contains 'vegan'.
EXPLAIN ANALYZE
SELECT * FROM products WHERE tags @> ARRAY['vegan'];

-- GIN also supports queries with multiple tags.
EXPLAIN ANALYZE
SELECT * FROM products WHERE tags @> ARRAY['vegan', 'organic'];
