BEGIN;

CREATE ROLE src;

ALTER ROLE src WITH LOGIN PASSWORD 'password';

GRANT CONNECT ON DATABASE coffee_store TO src;
GRANT USAGE ON SCHEMA sourcing TO src;
GRANT SELECT ON SCHEMA sourcing TO src;

-- INSERT INTO sourcing.supplier (name, code) values ('test', 'test')

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA sourcing TO src;

-- INSERT INTO sourcing.supplier (name, code) values ('test', 'test')

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA sourcing FROM src;

-- Also available as `CREATE ROLE sourcing_user WITH LOGIN PASSWORD 'password';`

COMMIT;
