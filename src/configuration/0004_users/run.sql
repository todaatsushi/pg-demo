BEGIN;

CREATE ROLE read_app_data;
CREATE ROLE write_app_data;
CREATE ROLE read_reporting;

GRANT USAGE ON SCHEMA application TO read_app_data;
GRANT USAGE ON SCHEMA application TO write_app_data;
GRANT USAGE ON SCHEMA reporting TO read_reporting;

GRANT SELECT ON ALL TABLES IN SCHEMA application TO read_app_data;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA application TO write_app_data;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA application TO write_app_data;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting TO read_reporting;

CREATE ROLE application WITH PASSWORD 'pg' LOGIN;
CREATE ROLE developer_ro WITH PASSWORD 'pg' LOGIN;
CREATE ROLE performance_monitoring WITH PASSWORD 'pg' LOGIN;
CREATE ROLE reporting WITH PASSWORD 'pg' LOGIN;

REVOKE CONNECT ON DATABASE grocery_store FROM PUBLIC;
GRANT CONNECT ON DATABASE grocery_store TO application;
GRANT CONNECT ON DATABASE grocery_store TO developer_ro;
GRANT CONNECT ON DATABASE grocery_store TO performance_monitoring;
GRANT CONNECT ON DATABASE grocery_store TO reporting;

GRANT write_app_data TO application;
GRANT read_app_data TO developer_ro;
GRANT read_reporting TO developer_ro;
GRANT read_app_data TO reporting;
GRANT read_reporting TO reporting;
GRANT pg_monitor TO performance_monitoring;

ALTER SCHEMA application OWNER TO application;
ALTER TABLE application.stores OWNER TO application;
ALTER TABLE application.staff OWNER TO application;
ALTER TABLE application.orders OWNER TO application;

ALTER SCHEMA reporting OWNER TO reporting;
ALTER MATERIALIZED VIEW reporting.staff_count_by_store_mat OWNER TO reporting;
ALTER VIEW reporting.staff_count_by_store OWNER TO reporting;
ALTER MATERIALIZED VIEW reporting.orders_by_day OWNER TO reporting;
ALTER VIEW reporting.orders_by_store OWNER TO reporting;
ALTER VIEW reporting.orders_by_staff OWNER TO reporting;

ALTER DEFAULT PRIVILEGES FOR ROLE application IN SCHEMA application
    GRANT SELECT ON TABLES TO read_app_data;
ALTER DEFAULT PRIVILEGES FOR ROLE application IN SCHEMA application
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO write_app_data;
ALTER DEFAULT PRIVILEGES FOR ROLE application IN SCHEMA application
    GRANT USAGE ON SEQUENCES TO write_app_data;

ALTER DEFAULT PRIVILEGES FOR ROLE reporting IN SCHEMA reporting
    GRANT SELECT ON TABLES TO read_reporting;

ALTER ROLE postgres SET search_path TO "$user", application, reporting, public;
ALTER ROLE application SET search_path TO "$user", application, public;
ALTER ROLE reporting SET search_path TO "$user", reporting, application, public;
ALTER ROLE developer_ro SET search_path TO "$user", application, reporting, public;

COMMIT;
