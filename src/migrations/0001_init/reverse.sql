-- Reverse 0001_init.sql
-- Drops all tables in dependency order.

BEGIN;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS stores;

DROP EXTENSION IF NOT EXISTS pg_buffercache;

COMMIT;
