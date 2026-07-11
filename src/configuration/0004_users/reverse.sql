-- Dependencies: none - run this before 0003_organisation/reverse.sql and 0002_data/reverse.sql

BEGIN;

GRANT CONNECT ON DATABASE grocery_store TO PUBLIC;

REASSIGN OWNED BY application TO postgres;
REASSIGN OWNED BY reporting TO postgres;

DROP ROLE IF EXISTS application;
DROP ROLE IF EXISTS developer_ro;
DROP ROLE IF EXISTS performance_monitoring;
DROP ROLE IF EXISTS reporting;

REVOKE ALL ON ALL TABLES IN SCHEMA application FROM read_app_data, write_app_data;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA application FROM write_app_data;
REVOKE ALL ON ALL TABLES IN SCHEMA reporting FROM read_reporting;
REVOKE ALL ON SCHEMA application FROM read_app_data, write_app_data;
REVOKE ALL ON SCHEMA reporting FROM read_reporting;

DROP ROLE IF EXISTS read_app_data;
DROP ROLE IF EXISTS write_app_data;
DROP ROLE IF EXISTS read_reporting;

COMMIT;
