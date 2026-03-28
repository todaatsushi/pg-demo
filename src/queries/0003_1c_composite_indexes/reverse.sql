-- Reverse 0003_1c_composite_indexes
DROP INDEX IF EXISTS idx_orders_single_customer_id;
DROP INDEX IF EXISTS idx_orders_composite_customer_status;
