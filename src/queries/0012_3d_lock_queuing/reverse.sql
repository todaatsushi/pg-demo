-- Reverse 0012_3d_lock_queuing
ALTER TABLE orders DROP COLUMN IF EXISTS queued_col;
