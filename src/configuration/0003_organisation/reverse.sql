-- Dependencies: run 0004_users/reverse.sql first if it has been applied

BEGIN;

DROP MATERIALIZED VIEW IF EXISTS reporting.staff_count_by_store_mat;
DROP MATERIALIZED VIEW IF EXISTS reporting.orders_by_day;
DROP VIEW IF EXISTS reporting.staff_count_by_store;
DROP VIEW IF EXISTS reporting.orders_by_store;
DROP VIEW IF EXISTS reporting.orders_by_staff;

ALTER TABLE application.orders SET SCHEMA public;
ALTER TABLE application.staff SET SCHEMA public;
ALTER TABLE application.stores SET SCHEMA public;

DROP SCHEMA IF EXISTS reporting;
DROP SCHEMA IF EXISTS application;

COMMIT;
