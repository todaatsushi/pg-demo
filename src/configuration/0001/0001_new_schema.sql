BEGIN;

REVOKE ALL ON DATABASE coffee_store, postgres, template1 FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS sourcing;

CREATE TABLE IF NOT EXISTS sourcing.supplier (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    code        text NOT NULL UNIQUE
);

COMMIT;
