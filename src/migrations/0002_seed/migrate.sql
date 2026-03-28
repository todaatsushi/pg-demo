-- 0002_seed.sql
-- Seed data for coffee store demo. Idempotent — safe to re-run.
-- Uses setseed() for approximate determinism — tag assignment may vary
-- across PG versions due to sort algorithm differences, but order
-- volumes and distributions will be consistent.

BEGIN;

-- ============================================================
-- Stores (5)
-- ============================================================
INSERT INTO stores (name, location)
SELECT name, location
FROM (VALUES
    ('London',  'United Kingdom'),
    ('Tokyo',   'Japan'),
    ('Berlin',  'Germany'),
    ('Sydney',  'Australia'),
    ('Toronto', 'Canada')
) AS v(name, location)
WHERE NOT EXISTS (SELECT 1 FROM stores LIMIT 1);

-- ============================================================
-- Staff (7 per store = 35)
-- ============================================================
INSERT INTO staff (name, store_id)
SELECT
    'staff_' || substr(md5(s.id::text || '_' || n::text), 1, 6),
    s.id
FROM stores s
CROSS JOIN generate_series(1, 7) AS n
WHERE NOT EXISTS (SELECT 1 FROM staff LIMIT 1);

-- ============================================================
-- Products (12 per store = 60)
-- ============================================================
INSERT INTO products (sku, name, price, type, tags, store_id)
SELECT
    'SKU-' || s.id || '-' || p.idx,
    p.product_name,
    p.price,
    p.product_type,
    -- Deterministic tag assignment using md5 of store_id + product_idx.
    -- Each product gets 1-3 tags. We use bit positions in the md5 hash
    -- to decide which tags to include.
    COALESCE(
        (SELECT array_agg(tag) FROM (
            SELECT tag, rn FROM unnest(ARRAY['vegan','takeaway only','in store only','offer','organic','fair trade']) WITH ORDINALITY AS t(tag, rn)
            WHERE get_byte(decode(md5(s.id::text || '-' || p.idx::text), 'hex'), 0) & (1 << ((rn::int - 1) % 8)) != 0
        ) sub),
        ARRAY['vegan']  -- fallback if bitmask selects no tags
    ),
    s.id
FROM stores s
CROSS JOIN (VALUES
    (1,  'English Breakfast',  3.50, 'tea (caffeine)'),
    (2,  'Chamomile Blend',    3.50, 'tea (non caffeinated)'),
    (3,  'Green Tea',          3.75, 'tea (caffeine)'),
    (4,  'Matcha Tea',         4.25, 'tea (caffeine)'),
    (5,  'Classic Americano',  3.80, 'americano'),
    (6,  'Single Espresso',    2.90, 'espresso'),
    (7,  'Double Espresso',    3.40, 'espresso'),
    (8,  'Oat Milk Latte',     4.50, 'latte'),
    (9,  'Vanilla Cappuccino', 4.50, 'cappuccino'),
    (10, 'Dark Mocha',         4.75, 'mocha'),
    (11, 'Hazelnut Mocha',     4.95, 'mocha'),
    (12, 'Classic Flat White', 4.20, 'flat white')
) AS p(idx, product_name, price, product_type)
WHERE NOT EXISTS (SELECT 1 FROM products LIMIT 1);

-- ============================================================
-- Customers + Orders
-- Uses a PL/pgSQL block to:
--   1. Generate customers with 1-20 orders each until 1M is reached
--   2. Expand into 1M order rows
-- ============================================================
DO $$
DECLARE
    target_orders  constant int := 1000000;
    total_assigned int := 0;
    cust_id        int := 0;
    order_count    int;
    product_count  int;
    staff_count    int;
BEGIN
    IF EXISTS (SELECT 1 FROM orders LIMIT 1) THEN
        RAISE NOTICE 'Orders already seeded, skipping.';
        RETURN;
    END IF;

    SELECT count(*) INTO product_count FROM products;
    SELECT count(*) INTO staff_count FROM staff;

    -- deterministic seed
    PERFORM setseed(0.42);

    -- Step 1: build temp table mapping customer_seq -> num_orders
    CREATE TEMP TABLE tmp_cust_orders (
        customer_seq int NOT NULL,
        num_orders   int NOT NULL
    ) ON COMMIT DROP;

    WHILE total_assigned < target_orders LOOP
        cust_id := cust_id + 1;
        order_count := 1 + floor(random() * 20)::int;
        IF total_assigned + order_count > target_orders THEN
            order_count := target_orders - total_assigned;
        END IF;
        INSERT INTO tmp_cust_orders VALUES (cust_id, order_count);
        total_assigned := total_assigned + order_count;
    END LOOP;

    RAISE NOTICE 'Generated % customers accounting for % orders', cust_id, total_assigned;

    -- Step 2: insert customers
    INSERT INTO customers (name, email)
    SELECT
        'cust_' || substr(md5(customer_seq::text), 1, 6),
        'cust_' || substr(md5(customer_seq::text), 1, 6) || '@example.com'
    FROM tmp_cust_orders;

    -- Step 3: expand customer orders into individual rows with real customer IDs
    CREATE TEMP TABLE tmp_order_rows (
        rn          int GENERATED ALWAYS AS IDENTITY,
        customer_id bigint NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO tmp_order_rows (customer_id)
    SELECT c.id
    FROM tmp_cust_orders co
    -- NOTE: assumes identity IDs start at 1 with no gaps on a fresh database.
    -- This holds when the seed runs in a single transaction on an empty table.
    JOIN customers c ON c.id = co.customer_seq
    CROSS JOIN LATERAL generate_series(1, co.num_orders);

    RAISE NOTICE 'Expanded to % order rows', (SELECT count(*) FROM tmp_order_rows);

    -- Step 4: insert orders using the row number for deterministic randomness
    -- We precompute random values in a CTE to avoid correlated subqueries per row.
    PERFORM setseed(0.42);

    -- Materialise product and staff ID arrays for O(1) lookup
    CREATE TEMP TABLE tmp_product_lookup (
        idx int,
        product_id bigint,
        product_type text,
        product_tags text[]
    ) ON COMMIT DROP;

    INSERT INTO tmp_product_lookup
    SELECT row_number() OVER (ORDER BY id)::int, id, type, tags FROM products;

    CREATE TEMP TABLE tmp_staff_lookup (
        idx int,
        staff_id bigint
    ) ON COMMIT DROP;

    INSERT INTO tmp_staff_lookup
    SELECT row_number() OVER (ORDER BY id)::int, id FROM staff;

    -- Generate random values in bulk, then join to lookups
    INSERT INTO orders (ordered_at, status, quantity, product_type, tags, product_id, customer_id, staff_id)
    SELECT
        '2026-01-01'::timestamp + (r.rand_ts * interval '30 days 23 hours 59 minutes'),
        CASE
            WHEN r.rand_status < 0.70 THEN 'completed'
            WHEN r.rand_status < 0.85 THEN 'pending'
            WHEN r.rand_status < 0.95 THEN 'cancelled'
            ELSE 'refunded'
        END,
        1 + floor(r.rand_qty * 5)::int,
        pl.product_type,
        pl.product_tags,
        pl.product_id,
        r.customer_id,
        sl.staff_id
    FROM (
        SELECT
            customer_id,
            random() AS rand_ts,
            random() AS rand_status,
            random() AS rand_qty,
            1 + floor(random() * product_count)::int AS prod_idx,
            1 + floor(random() * staff_count)::int AS staff_idx
        FROM tmp_order_rows
    ) r
    JOIN tmp_product_lookup pl ON pl.idx = r.prod_idx
    JOIN tmp_staff_lookup sl ON sl.idx = r.staff_idx;

    RAISE NOTICE 'Inserted 1M orders.';
END $$;

COMMIT;
