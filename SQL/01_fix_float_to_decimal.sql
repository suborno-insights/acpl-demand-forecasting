-- ============================================================
-- Step: Convert float -> decimal for currency/percentage/quantity columns
-- (avoids floating-point rounding error in financial calculations)
-- ============================================================
USE ACPL_DemandForecasting;
GO

ALTER TABLE products ALTER COLUMN unit_cost DECIMAL(10,2) NULL;
ALTER TABLE products ALTER COLUMN unit_price DECIMAL(10,2) NULL;  -- NULL allowed: P053 has a genuinely missing unit_price
GO

ALTER TABLE promotions ALTER COLUMN discount_pct DECIMAL(5,2) NULL;
GO

ALTER TABLE purchase_orders ALTER COLUMN unit_cost DECIMAL(10,2) NOT NULL;
ALTER TABLE purchase_orders ALTER COLUMN qty_rejected DECIMAL(10,1) NULL;
ALTER TABLE purchase_orders ALTER COLUMN calculated_total DECIMAL(12,2) NULL;
GO

ALTER TABLE warehouses ALTER COLUMN capacity_units DECIMAL(12,1) NULL;
GO

ALTER TABLE inventory_snapshots ALTER COLUMN stock_qty DECIMAL(12,1) NULL;
GO

ALTER TABLE sales_transactions ALTER COLUMN unit_price DECIMAL(10,2) NULL;
ALTER TABLE sales_transactions ALTER COLUMN discount_pct DECIMAL(5,2) NULL;
ALTER TABLE sales_transactions ALTER COLUMN total_amount DECIMAL(12,2) NULL;
GO
