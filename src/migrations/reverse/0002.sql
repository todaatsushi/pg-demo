-- Reverse 0002_seed.sql
-- Deletes all seed data in dependency order, preserving schema.

BEGIN;

DELETE FROM orders;
DELETE FROM customers;
DELETE FROM products;
DELETE FROM staff;
DELETE FROM stores;

COMMIT;
