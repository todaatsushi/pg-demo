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

CREATE TABLE IF NOT EXISTS orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product     text NOT NULL,
    units       int NOT NULL,
    ordered_at  timestamp NOT NULL DEFAULT now(),
    store_id    bigint NOT NULL REFERENCES stores (id),
    staff_id    bigint NOT NULL REFERENCES staff (id)
);

INSERT INTO stores (name, location)
SELECT name, location
FROM (VALUES
    ('Regent Street',  'London, United Kingdom'),
    ('Ginza',   'Tokyo, Japan'),
    ('Southgate', 'London, United Kingdom')
) AS v(name, location)
WHERE NOT EXISTS (SELECT 1 FROM stores LIMIT 1);

INSERT INTO staff (name, store_id)
SELECT
    'staff_' || substr(md5(s.id::text || '_' || n::text), 1, 6),
    s.id
FROM stores s
CROSS JOIN generate_series(1, 7) AS n
WHERE NOT EXISTS (SELECT 1 FROM staff LIMIT 1);

COMMIT;
