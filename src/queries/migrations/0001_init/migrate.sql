-- 0001_init.sql
-- Base schema for coffee store demo. Idempotent — safe to re-run.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_buffercache;

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

CREATE TABLE IF NOT EXISTS customers (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    email       text
);

CREATE TABLE IF NOT EXISTS products (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku         text NOT NULL,
    name        text NOT NULL,
    price       numeric(10,2) NOT NULL,
    type        text NOT NULL,
    tags        text[],
    store_id    bigint NOT NULL REFERENCES stores (id)
);

CREATE TABLE IF NOT EXISTS orders (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ordered_at      timestamp NOT NULL DEFAULT now(),
    status          text NOT NULL DEFAULT 'pending',
    quantity        int NOT NULL,
    product_type    text NOT NULL,
    tags            text[],
    product_id      bigint NOT NULL REFERENCES products (id),
    customer_id     bigint NOT NULL REFERENCES customers (id),
    staff_id        bigint NOT NULL REFERENCES staff (id),
    CONSTRAINT orders_status_check CHECK (status IN ('pending', 'completed', 'cancelled', 'refunded'))
);

COMMIT;
