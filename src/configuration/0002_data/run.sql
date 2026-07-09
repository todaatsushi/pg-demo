-- Adapted from src/migrations/0001_init/migrate.sql + src/migrations/0002_seed/migrate.sql

BEGIN;

CREATE TABLE IF NOT EXISTS stores (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    location    text
);

CREATE TABLE IF NOT EXISTS staff (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    store_id    bigint NOT NULL REFERENCES stores (id)
);

-- ============================================================
-- Stores (3)
-- ============================================================
INSERT INTO stores (name, location)
SELECT name, location
FROM (VALUES
    ('Regent Street',  'London, United Kingdom'),
    ('Ginza',   'Tokyo, Japan'),
    ('Southgate', 'London, United Kingdom')
) AS v(name, location)
WHERE NOT EXISTS (SELECT 1 FROM stores LIMIT 1);

-- ============================================================
-- Staff (7 per store = 21)
-- ============================================================
INSERT INTO staff (name, store_id)
SELECT
    'staff_' || substr(md5(s.id::text || '_' || n::text), 1, 6),
    s.id
FROM stores s
CROSS JOIN generate_series(1, 7) AS n
WHERE NOT EXISTS (SELECT 1 FROM staff LIMIT 1);

-- ============================================================
-- Views: staff count by store
-- ============================================================

-- Regular view: recomputed on every query
CREATE OR REPLACE VIEW staff_count_by_store AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM stores s
LEFT JOIN staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

-- Materialised view: stored snapshot, refresh manually
CREATE MATERIALIZED VIEW IF NOT EXISTS staff_count_by_store_mat AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM stores s
LEFT JOIN staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

COMMIT;

-- ============================================================
-- Demo: materialised view is "frozen" after an insert
-- ============================================================
-- Insert an extra staff member into the first store
INSERT INTO staff (name, store_id)
SELECT 'staff_demo', id FROM stores ORDER BY id LIMIT 1;

-- Regular view reflects the new row immediately
SELECT 'regular view' AS source, store_name, staff_count FROM staff_count_by_store ORDER BY store_id;

-- Materialised view still shows the old count
SELECT 'materialised view (stale)' AS source, store_name, staff_count FROM staff_count_by_store_mat ORDER BY store_id;

-- After refresh, materialised view catches up
-- REFRESH MATERIALIZED VIEW staff_count_by_store_mat;
-- SELECT 'materialised view (refreshed)' AS source, store_name, staff_count FROM staff_count_by_store_mat ORDER BY store_id;
