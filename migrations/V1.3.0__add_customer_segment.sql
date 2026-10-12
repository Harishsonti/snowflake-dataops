-- Add an optional customer segmentation attribute.
-- This additive change preserves existing rows and can be safely re-run.
ALTER TABLE DATAOPS_DEMO.CUSTOMERS
    ADD COLUMN IF NOT EXISTS CUSTOMER_SEGMENT VARCHAR(30);
