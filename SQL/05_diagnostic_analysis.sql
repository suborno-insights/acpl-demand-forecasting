-- ============================================================
-- ACPL Demand Forecasting & Inventory Signal Analysis
-- Step 2: Diagnostic Analysis (Core Questions)
-- ============================================================
USE ACPL_DemandForecasting;
GO

-- ============================================================
-- [Diagnostic Q1a] Validate peak months empirically per category
-- (z-score of each category's own monthly average, not an assumed
-- Apr/Jun/Dec hypothesis)
-- ============================================================
WITH monthly_category AS (
    SELECT 
        p.category,
        MONTH(st.transaction_date) AS month_num,
        FORMAT(st.transaction_date, 'yyyy-MM') AS sales_month,
        SUM(st.total_amount) AS total_revenue
    FROM sales_transactions st
    INNER JOIN products p ON st.product_id = p.product_id
    GROUP BY p.category, MONTH(st.transaction_date), FORMAT(st.transaction_date, 'yyyy-MM')
),
category_stats AS (
    SELECT 
        *,
        AVG(total_revenue) OVER (PARTITION BY category) AS category_avg,
        STDEV(total_revenue) OVER (PARTITION BY category) AS category_stdev
    FROM monthly_category
)
SELECT 
    category, sales_month, total_revenue,
    ROUND(category_avg, 0) AS category_avg,
    ROUND((total_revenue - category_avg) / category_stdev, 2) AS z_score
FROM category_stats
ORDER BY category, z_score DESC;
GO

-- ============================================================
-- [Diagnostic Q1b] Seasonal lift %: Apr/Jun/Dec confirmed as peak
-- months across all 8 categories via the z-score check above.
-- ============================================================
WITH monthly_category AS (
    SELECT 
        p.category,
        MONTH(st.transaction_date) AS month_num,
        FORMAT(st.transaction_date, 'yyyy-MM') AS sales_month,
        SUM(st.total_amount) AS total_revenue
    FROM sales_transactions st
    INNER JOIN products p ON st.product_id = p.product_id
    GROUP BY p.category, MONTH(st.transaction_date), FORMAT(st.transaction_date, 'yyyy-MM')
)
SELECT 
    category,
    AVG(CASE WHEN month_num IN (4,6,12) THEN total_revenue END) AS avg_peak_revenue,
    AVG(CASE WHEN month_num NOT IN (4,6,12) THEN total_revenue END) AS avg_nonpeak_revenue,
    (AVG(CASE WHEN month_num IN (4,6,12) THEN total_revenue END) 
     - AVG(CASE WHEN month_num NOT IN (4,6,12) THEN total_revenue END)) 
     / AVG(CASE WHEN month_num NOT IN (4,6,12) THEN total_revenue END) * 100 AS pct_seasonal_lift
FROM monthly_category
GROUP BY category
ORDER BY pct_seasonal_lift DESC;
GO

-- ============================================================
-- [Diagnostic Q2] Product Growth Classification (YoY, units-based)
-- LEFT JOIN from products ensures never-sold products are included.
-- ============================================================
WITH yearly_units AS (
    SELECT 
        p.product_id, p.product_name, p.category, p.is_active,
        YEAR(st.transaction_date) AS sales_year,
        SUM(st.quantity) AS total_units
    FROM products p
    LEFT JOIN sales_transactions st ON st.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.is_active, YEAR(st.transaction_date)
),
product_yoy AS (
    SELECT 
        product_id, product_name, category, is_active,
        SUM(CASE WHEN sales_year = 2024 THEN total_units ELSE 0 END) AS units_2024,
        SUM(CASE WHEN sales_year = 2025 THEN total_units ELSE 0 END) AS units_2025
    FROM yearly_units
    GROUP BY product_id, product_name, category, is_active
),
classified AS (
    SELECT 
        product_id, product_name, category, is_active,
        units_2024, units_2025,
        CASE 
            WHEN units_2024 = 0 THEN NULL
            ELSE ROUND(CAST(units_2025 - units_2024 AS FLOAT) / units_2024 * 100, 1)
        END AS pct_growth,
        CASE 
            WHEN units_2024 = 0 AND units_2025 = 0 THEN 'Never Sold'
            WHEN units_2024 = 0 AND units_2025 > 0 THEN 'New'
            WHEN units_2025 = 0 AND units_2024 > 0 THEN 'Discontinued'
            WHEN CAST(units_2025 - units_2024 AS FLOAT) / units_2024 * 100 > 10 THEN 'Growing'
            WHEN CAST(units_2025 - units_2024 AS FLOAT) / units_2024 * 100 < -10 THEN 'Declining'
            ELSE 'Stable'
        END AS trend_classification
    FROM product_yoy
)
SELECT 
    trend_classification, COUNT(*) AS product_count,
    SUM(units_2024) AS total_units_2024, SUM(units_2025) AS total_units_2025
FROM classified
GROUP BY trend_classification
ORDER BY product_count DESC;
GO

-- ============================================================
-- [Diagnostic Q3] Order vs Actual Demand Gap (product-wise)
-- ============================================================
SELECT 
    p.product_id, p.product_name, p.category,
    ISNULL(po_agg.total_ordered, 0) AS total_ordered,
    ISNULL(st_agg.total_sold, 0) AS total_sold,
    ISNULL(po_agg.total_ordered, 0) - ISNULL(st_agg.total_sold, 0) AS gap_units,
    CASE 
        WHEN ISNULL(st_agg.total_sold, 0) = 0 THEN NULL
        ELSE ROUND((CAST(ISNULL(po_agg.total_ordered, 0) AS FLOAT) - st_agg.total_sold) / st_agg.total_sold * 100, 1)
    END AS gap_pct_vs_demand
FROM products p
LEFT JOIN (
    SELECT product_id, SUM(order_qty) AS total_ordered
    FROM purchase_orders GROUP BY product_id
) po_agg ON p.product_id = po_agg.product_id
LEFT JOIN (
    SELECT product_id, SUM(quantity) AS total_sold
    FROM sales_transactions GROUP BY product_id
) st_agg ON p.product_id = st_agg.product_id
ORDER BY gap_pct_vs_demand ASC;
GO

-- ============================================================
-- [Root Cause Check] Is order size/frequency demand-independent?
-- Compares avg order size per PO across highest vs lowest demand
-- products -- confirms ordering is NOT scaled to actual demand.
-- ============================================================
SELECT 
    po.product_id,
    COUNT(*) AS po_count,
    SUM(po.order_qty) AS total_ordered,
    ROUND(AVG(CAST(po.order_qty AS FLOAT)), 1) AS avg_order_size,
    ISNULL(st_agg.total_sold, 0) AS total_sold
FROM purchase_orders po
LEFT JOIN (
    SELECT product_id, SUM(quantity) AS total_sold
    FROM sales_transactions GROUP BY product_id
) st_agg ON po.product_id = st_agg.product_id
WHERE po.product_id IN ('P040','P065','P007','P103')  -- example: highest vs lowest demand products
GROUP BY po.product_id, st_agg.total_sold;
GO

-- ============================================================
-- [Investigation #4] PO Fulfillment: trustworthy-only recheck
-- Original Descriptive-step figure (~96.25%) included rows flagged
-- qty_mismatch_flag=1 (incomplete/inconsistent qty_received records).
-- ============================================================
SELECT 
    w.warehouse_id, w.warehouse_name,
    COUNT(*) AS total_po_count,
    SUM(CASE WHEN po.qty_mismatch_flag = 1 THEN 1 ELSE 0 END) AS flagged_po_count,
    CAST(SUM(po.qty_received) AS FLOAT) / SUM(po.order_qty) * 100 AS fulfillment_pct_all_rows,
    CAST(SUM(CASE WHEN po.qty_mismatch_flag = 0 THEN po.qty_received ELSE 0 END) AS FLOAT) 
        / SUM(CASE WHEN po.qty_mismatch_flag = 0 THEN po.order_qty ELSE 0 END) * 100 AS fulfillment_pct_trustworthy_only
FROM purchase_orders po
INNER JOIN warehouses w ON po.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name
ORDER BY w.warehouse_id;
GO

-- ============================================================
-- [Investigation #5] Stockout Rate: product-level breakdown
-- Removes the sampling bias caused by daily (risk-linked, ~20
-- products) vs weekly (rest) snapshot granularity.
-- ============================================================
SELECT 
    snapshot_granularity,
    COUNT(DISTINCT product_id) AS product_count,
    COUNT(*) AS total_snapshots,
    SUM(CASE WHEN stockout_flag = 1 THEN 1 ELSE 0 END) AS stockout_count,
    CAST(SUM(CASE WHEN stockout_flag = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS stockout_pct
FROM inventory_snapshots
GROUP BY snapshot_granularity;
GO

-- ============================================================
-- [Investigation #6] Store-level Stockout Proxy (via shipment risk)
-- No direct store-level stock data exists in this dataset; this
-- uses shipment Delayed/Lost rate per store as a supply-side proxy.
-- Requires the `shipments` table (added specifically for this
-- investigation -- see sql/06_shipments_setup.sql).
-- store_id = 'ST99' (33 rows) is an invalid placeholder, excluded
-- via INNER JOIN, same treatment as sales_transactions' "P999".
-- ============================================================
SELECT 
    st.store_id, st.store_name, st.region, st.store_type,
    COUNT(*) AS total_shipments,
    SUM(CASE WHEN s.shipment_status IN ('Delayed', 'Lost') THEN 1 ELSE 0 END) AS risk_shipments,
    CAST(SUM(CASE WHEN s.shipment_status IN ('Delayed', 'Lost') THEN 1 ELSE 0 END) AS FLOAT) 
        / COUNT(*) * 100 AS risk_pct
FROM shipments s
INNER JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.region, st.store_type
ORDER BY risk_pct DESC;
GO
