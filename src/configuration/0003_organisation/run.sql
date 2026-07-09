BEGIN;


CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS application;

ALTER TABLE stores SET SCHEMA application;
ALTER TABLE staff SET SCHEMA application;

-- Move materialised view to reporting schema
ALTER MATERIALIZED VIEW staff_count_by_store_mat SET SCHEMA reporting;

-- Regular views cannot be moved with ALTER; drop and recreate in reporting schema
DROP VIEW staff_count_by_store;
CREATE OR REPLACE VIEW reporting.staff_count_by_store AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM application.stores s
LEFT JOIN application.staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

SET search_path TO "$user",application,reporting,public;

COMMIT;
