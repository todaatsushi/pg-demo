-- Dependencies: run 0003_organisation/reverse.sql first if it has been applied
-- (tables will be schema-qualified after 0003 runs)

BEGIN;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS stores;

COMMIT;
