-- ============================================================
-- ACPL Demand Forecasting & Inventory Signal Analysis
-- Step 1: Descriptive Analysis
-- ============================================================
USE ACPL_DemandForecasting;
GO

-- ============================================================
-- [Supporting Q7] Data Coverage Check
-- Verifies no missing months/stores before trusting the trend data.
-- ============================================================
SELECT 
    FORMAT(transaction_date, 'yyyy-MM') AS sales_month,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT store_id) AS active_stores,
    COUNT(DISTINCT product_id) AS distinct_products_sold,
    SUM(quantity) AS total_units
FROM sales_transactions
GROUP BY FORMAT(transaction_date, 'yyyy-MM')
ORDER BY sales_month;
GO

-- ============================================================
-- [Core Q1] Overall Baseline KPI (24 months)
-- INNER JOIN excludes the 273 "P999" orphan rows (unknown product).
-- ============================================================
SELECT 
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT st.customer_id) AS unique_customers,
    SUM(st.quantity) AS total_units_sold,
    SUM(st.total_amount) AS total_revenue,
    AVG(st.total_amount) AS avg_transaction_value
FROM sales_transactions st
INNER JOIN products p ON st.product_id = p.product_id;
GO

-- Data reliability check: total_amount vs quantity*unit_price
SELECT 
    COUNT(*) AS mismatched_rows,
    CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM sales_transactions) * 100 AS pct_of_total
FROM sales_transactions
WHERE total_amount <> (quantity * unit_price);
GO

-- ============================================================
-- [Core Q2] Category-wise Monthly Sales Trend
-- ============================================================
SELECT 
    p.category,
    FORMAT(st.transaction_date, 'yyyy-MM') AS sales_month,
    SUM(st.total_amount) AS total_revenue,
    SUM(st.quantity) AS total_units,
    COUNT(*) AS transaction_count
FROM sales_transactions st
INNER JOIN products p ON st.product_id = p.product_id
GROUP BY p.category, FORMAT(st.transaction_date, 'yyyy-MM')
ORDER BY p.category, sales_month;
GO

-- ============================================================
-- [Core Q3] Store-wise and Region-wise Sales Distribution
-- ============================================================
SELECT 
    s.store_id,
    s.store_name,
    s.region,
    s.store_type,
    SUM(st.total_amount) AS total_revenue,
    SUM(st.quantity) AS total_units,
    COUNT(*) AS transaction_count
FROM sales_transactions st
INNER JOIN stores s ON st.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.region, s.store_type
ORDER BY total_revenue DESC;
GO

-- ============================================================
-- [Core Q4] Top / Bottom 10 Products by Demand Volume (units, not revenue --
-- revenue mixes price and volume, and stockout risk is a volume problem)
-- ============================================================
SELECT TOP 10
    p.product_id, p.product_name, p.category,
    SUM(st.quantity) AS total_units,
    SUM(st.total_amount) AS total_revenue,
    COUNT(*) AS transaction_count
FROM sales_transactions st
INNER JOIN products p ON st.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_units DESC;
GO

SELECT TOP 10
    p.product_id, p.product_name, p.category,
    SUM(st.quantity) AS total_units,
    SUM(st.total_amount) AS total_revenue,
    COUNT(*) AS transaction_count
FROM sales_transactions st
INNER JOIN products p ON st.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_units ASC;
GO

-- ============================================================
-- [Core Q5] Warehouse-wise Purchase Order Fulfillment
-- Caveat: purchase_orders.qty_mismatch_flag rows may distort this;
-- revisit with a "trustworthy-only" filter in Diagnostic step.
-- ============================================================
SELECT 
    w.warehouse_id, w.warehouse_name, w.region,
    COUNT(*) AS total_po_count,
    SUM(po.order_qty) AS total_ordered,
    SUM(po.qty_received) AS total_received,
    SUM(po.order_qty) - SUM(po.qty_received) AS gap_units,
    CAST(SUM(po.qty_received) AS FLOAT) / SUM(po.order_qty) * 100 AS fulfillment_pct
FROM purchase_orders po
INNER JOIN warehouses w ON po.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name, w.region
ORDER BY fulfillment_pct ASC;
GO

-- ============================================================
-- [Core Q6] Stockout Rate, Warehouse-wise
-- Caveat: ~20 risk-linked products get daily snapshots vs. weekly for
-- the rest, so this average is weighted toward risk-linked products.
-- ============================================================
SELECT 
    w.warehouse_id, w.warehouse_name, w.region,
    COUNT(*) AS total_snapshots,
    SUM(CASE WHEN inv.stockout_flag = 1 THEN 1 ELSE 0 END) AS stockout_count,
    CAST(SUM(CASE WHEN inv.stockout_flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS stockout_pct
FROM inventory_snapshots inv
INNER JOIN warehouses w ON inv.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name, w.region
ORDER BY stockout_pct DESC;
GO

-- ============================================================
-- [Supporting Q8] Product Portfolio Mix
-- ============================================================
SELECT 
    category,
    COUNT(*) AS total_products,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_products
FROM products
GROUP BY category
ORDER BY total_products DESC;
GO
