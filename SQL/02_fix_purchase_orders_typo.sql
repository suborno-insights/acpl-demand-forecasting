-- ============================================================
-- Fix: purchase_orders.product_id had a trailing 'X' typo
-- (e.g. 'P009X' should be 'P009') on 53 rows.
-- Verified: stripping the trailing X on every affected value
-- produces a valid, existing product_id in the products table.
-- ============================================================
USE ACPL_DemandForecasting;
GO

-- Preview before fixing (run this first to sanity-check)
SELECT po_id, product_id, LEFT(product_id, LEN(product_id)-1) AS proposed_fix
FROM purchase_orders
WHERE product_id LIKE 'P%X'
  AND product_id NOT IN (SELECT product_id FROM products);
GO

-- Apply the fix
UPDATE purchase_orders
SET product_id = LEFT(product_id, LEN(product_id)-1)
WHERE product_id LIKE 'P%X'
  AND product_id NOT IN (SELECT product_id FROM products);
GO

-- Verify: should now return 0 rows
SELECT COUNT(*) AS remaining_orphans
FROM purchase_orders po
LEFT JOIN products p ON po.product_id = p.product_id
WHERE p.product_id IS NULL;
GO
