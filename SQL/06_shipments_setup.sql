-- ============================================================
-- ACPL Demand Forecasting & Inventory Signal Analysis
-- shipments table setup
-- (Table imported later, specifically for Diagnostic Investigation #6:
-- store-level stockout proxy via shipment risk. Not part of the
-- original 7-table Project 1 scope -- see sql/00_setup_notes.md.)
--
-- Imported via SSMS Import Flat File wizard, same as the other 7
-- tables -- ID columns (shipment_id, warehouse_id, store_id,
-- carrier_id) manually forced to nvarchar(50) to avoid the wizard's
-- money-type auto-detect corruption bug encountered earlier.
-- ============================================================
USE ACPL_DemandForecasting;
GO

-- float -> decimal (currency/quantity precision)
ALTER TABLE shipments ALTER COLUMN distance_km DECIMAL(10,2) NULL;
GO
ALTER TABLE shipments ALTER COLUMN shipment_cost DECIMAL(10,2) NULL;
GO

-- Foreign Key to warehouses. store_id FK intentionally NOT added:
-- 33 rows have store_id = 'ST99', a genuine invalid placeholder
-- (already flagged by the pre-existing store_id_invalid_flag column
-- from the original data cleaning) -- not a fixable typo like
-- purchase_orders' "PxxxX" case. Excluded via INNER JOIN in analysis
-- queries instead, same treatment as sales_transactions' "P999".
ALTER TABLE shipments ADD CONSTRAINT FK_shipments_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
GO

-- Verify row count (expected: 8,968)
SELECT COUNT(*) AS row_count FROM shipments;
GO
