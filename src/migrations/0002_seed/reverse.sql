-- Reverse 0002_seed.sql
-- Truncates all seed data, preserving schema.
-- Uses TRUNCATE instead of DELETE for speed on large tables.

BEGIN;

TRUNCATE orders, customers, products, staff, stores CASCADE;

COMMIT;
