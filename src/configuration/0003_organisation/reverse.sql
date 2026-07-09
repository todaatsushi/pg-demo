-- Dependencies: run 0004_users/reverse.sql first if it has been applied
-- (roles hold grants on the schemas/tables; must be revoked before dropping schemas)

BEGIN;

-- Move materialised view back to public
ALTER MATERIALIZED VIEW reporting.staff_count_by_store_mat SET SCHEMA public;

-- Regular view cannot be moved; drop and recreate in public
-- (tables will be back in public after the ALTER TABLE steps below)
DROP VIEW reporting.staff_count_by_store;
CREATE OR REPLACE VIEW public.staff_count_by_store AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM public.stores s
LEFT JOIN public.staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

-- Move tables back to public (staff first due to FK reference to stores)
ALTER TABLE application.staff SET SCHEMA public;
ALTER TABLE application.stores SET SCHEMA public;

-- Drop schemas now that they are empty
DROP SCHEMA IF EXISTS reporting;
DROP SCHEMA IF EXISTS application;

COMMIT;
