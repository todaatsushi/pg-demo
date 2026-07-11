BEGIN;

CREATE SCHEMA IF NOT EXISTS reporting;
CREATE SCHEMA IF NOT EXISTS application;

ALTER TABLE stores SET SCHEMA application;
ALTER TABLE staff SET SCHEMA application;
ALTER TABLE orders SET SCHEMA application;

-- reporting schema is now separate; create views there
CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.staff_count_by_store_mat AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM application.stores s
LEFT JOIN application.staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

CREATE MATERIALIZED VIEW IF NOT EXISTS reporting.orders_by_day AS
SELECT
    date_trunc('day', ordered_at) AS day,
    count(*) AS order_count,
    sum(units) AS total_units
FROM application.orders
GROUP BY date_trunc('day', ordered_at)
ORDER BY day;

CREATE OR REPLACE VIEW reporting.staff_count_by_store AS
SELECT s.id AS store_id, s.name AS store_name, count(st.id) AS staff_count
FROM application.stores s
LEFT JOIN application.staff st ON st.store_id = s.id
GROUP BY s.id, s.name;

CREATE OR REPLACE VIEW reporting.orders_by_store AS
SELECT s.id AS store_id, s.name AS store_name,
       count(*) AS order_count, sum(o.units) AS total_units
FROM application.orders o
JOIN application.stores s ON s.id = o.store_id
GROUP BY s.id, s.name;

CREATE OR REPLACE VIEW reporting.orders_by_staff AS
SELECT st.id AS staff_id, st.name AS staff_name,
       count(*) AS order_count, sum(o.units) AS total_units
FROM application.orders o
JOIN application.staff st ON st.id = o.staff_id
GROUP BY st.id, st.name;

COMMIT;
