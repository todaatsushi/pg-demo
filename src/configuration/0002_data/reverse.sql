-- Dependencies: run 0003_organisation/reverse.sql first if it has been applied
-- (views and tables will be schema-qualified after 0003 runs)

BEGIN;

DROP MATERIALIZED VIEW IF EXISTS staff_count_by_store_mat;
DROP VIEW IF EXISTS staff_count_by_store;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS stores;

COMMIT;
