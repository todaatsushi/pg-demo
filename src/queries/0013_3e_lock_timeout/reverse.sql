-- Reverse 0013_3e_lock_timeout
ALTER TABLE orders DROP COLUMN IF EXISTS timeout_col;
RESET lock_timeout;
