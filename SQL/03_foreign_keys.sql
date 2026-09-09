-- ============================================================
-- ACPL Demand Forecasting & Inventory Signal Analysis
-- Foreign Key relationships
--
-- NOTE: sales_transactions.product_id -> products.product_id is
-- intentionally NOT enforced as a Foreign Key. 273 rows (0.09%)
-- reference "P999", a genuine unknown/deleted-product placeholder
-- per the data dictionary -- not a fixable data-entry error (see
-- 02_fix_purchase_orders_typo.sql for a case that WAS fixable).
-- Product-level analysis uses INNER JOIN, which naturally excludes
-- these rows.
-- ============================================================
USE ACPL_DemandForecasting;
GO

ALTER TABLE promotions ADD CONSTRAINT FK_promotions_product
    FOREIGN KEY (product_id) REFERENCES products(product_id);
GO

ALTER TABLE purchase_orders ADD CONSTRAINT FK_po_product
    FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE purchase_orders ADD CONSTRAINT FK_po_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
GO

ALTER TABLE inventory_snapshots ADD CONSTRAINT FK_inv_product
    FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE inventory_snapshots ADD CONSTRAINT FK_inv_warehouse
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
GO

ALTER TABLE sales_transactions ADD CONSTRAINT FK_sales_store
    FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE sales_transactions ADD CONSTRAINT FK_sales_promo
    FOREIGN KEY (promo_id) REFERENCES promotions(promo_id);
GO

-- Verification: should list all 7 constraints
SELECT 
    fk.name AS constraint_name,
    OBJECT_NAME(fk.parent_object_id) AS table_name,
    OBJECT_NAME(fk.referenced_object_id) AS references_table
FROM sys.foreign_keys fk
ORDER BY table_name;
GO
