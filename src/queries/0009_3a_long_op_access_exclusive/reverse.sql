-- Reverse 0009_3a_long_op_access_exclusive
-- Change ordered_at back to timestamp if the ALTER succeeded.
ALTER TABLE orders ALTER COLUMN ordered_at TYPE timestamp;
