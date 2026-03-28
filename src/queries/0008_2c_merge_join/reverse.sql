-- Reverse 0008_2c_merge_join
RESET enable_hashjoin;
RESET enable_nestloop;
DROP INDEX IF EXISTS idx_orders_merge_join_customer_id;
