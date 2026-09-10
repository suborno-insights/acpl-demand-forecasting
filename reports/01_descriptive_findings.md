# Step 1: Descriptive Analysis — Findings

## 📊 Baseline KPIs (2024-01 to 2025-12)

| Metric | Value |
|---|---|
| Total transactions (valid) | 288,090 |
| Unique customers | 5,979 |
| Total units sold | 575,238 |
| Total revenue | ৳12,91,12,162.47 |
| Avg transaction value | ৳448.17 |
| Data reliability | 99.95% (145 rows / 0.05% show a `total_amount` vs `quantity×unit_price` mismatch — consistent with documented dataset outliers, negligible impact) |

Note: 273 transactions (0.09%) reference an unknown product ("P999") and are excluded from all product-level figures via `INNER JOIN`.

## 📈 Category-wise Monthly Trend

- All 8 categories show **synchronized spikes** in April, June, and December — a strong signal of company-wide seasonality (Boishakh, Eid, year-end) rather than category-specific behavior.
- Grocery and Beverages are the largest categories by revenue and show the largest absolute swings (Grocery: ~৳2.1–2.5M baseline months up to ~৳3.5M+ in peak months).
- Most categories trend upward from 2024 to 2025 in like-for-like months.

## 🏬 Store & Region Distribution

- Clear tiering by `store_type`: Flagship (2 stores) >> Standard (11 stores) >> Express (7 stores).
- Express stores show a "frequent visit, smaller basket" pattern — comparable transaction counts to some Standard stores but noticeably lower revenue per transaction (~৳320 vs ~৳429), consistent with the data dictionary's design note.
- Region-level rollup was intentionally skipped: two regions (Rajshahi, Sylhet) each host a Flagship store, which would confound a simple regional revenue comparison. Revisit with store-type normalization if needed in Diagnostic step.

## 📦 Top / Bottom 10 Products (by unit volume, not revenue)

- Top 10 are entirely Grocery products — highest stockout risk given highest demand volume.
- Bottom 10 are entirely Electronics Accessories and Footwear — negligible stockout risk.
- Revenue ranking would give a different, less useful picture for this project (e.g. product P036: lowest unit volume in the top-10 set but highest revenue — a low-volume, high-price item). Units chosen as the ranking metric deliberately.

## 🚚 Purchase Order Fulfillment (Warehouse-wise)

| Warehouse | Fulfillment % | Gap (units) |
|---|---|---|
| W01 – Dhaka Central DC | 96.26% | 141,103 |
| W03 – Rajshahi Regional DC | 96.26% | 140,844 |
| W02 – Chattogram Regional DC | 96.28% | 139,273 |

All three warehouses show near-identical fulfillment rates — suggests a systemic/company-wide pattern rather than a warehouse-specific operational issue. Caveat: this number is not yet adjusted for `purchase_orders.qty_mismatch_flag` rows (data-quality flagged in cleaning); revisit with a trustworthy-only filter in Diagnostic step.

## ⚠️ Stockout Rate (Warehouse-wise)

| Warehouse | Stockout % |
|---|---|
| W01 – Dhaka Central DC | 15.96% |
| W03 – Rajshahi Regional DC | 15.55% |
| W02 – Chattogram Regional DC | 15.27% |

Again uniform across warehouses. **Important caveat**: `inventory_snapshots` uses daily granularity for ~20 risk-linked products and weekly for the rest — this average is disproportionately weighted toward risk-linked products, not representative of the full 180-product catalog. Needs product-level breakdown in Diagnostic step.

## 🗂️ Product Portfolio Mix

| Category | Total Products | Active Products |
|---|---|---|
| Grocery | 44 | 41 |
| Beverages | 25 | 21 |
| Personal Care | 25 | 18 |
| Electronics Accessories | 22 | 20 |
| Home & Kitchen | 19 | 15 |
| Apparel | 17 | 9 |
| Stationery | 14 | 12 |
| Footwear | 14 | 12 |

Grocery's dominance in top-demand products is partly (not fully) explained by having the largest product portfolio (44 products). Apparel stands out with only 53% of products active — the rest should be excluded from forecasting since they're discontinued.

## 🔍 Data Quality Notes Carried Forward

1. **273 "P999" transactions** — genuine unknown-product placeholder, unfixable, excluded via INNER JOIN throughout.
2. **53 purchase_orders rows** had a trailing-typo product_id (e.g. "P009X") — fixed via UPDATE after confirming the typo pattern.
3. **145 sales_transactions rows (0.05%)** — `total_amount` doesn't match `quantity×unit_price`; documented dataset outlier, negligible.
4. **Apparel category** — ~47% of products inactive; exclude from forward-looking forecasts.
5. **Stockout rate figures** — biased toward the ~20 risk-linked products due to daily vs. weekly snapshot granularity; needs re-measurement at product level.
6. **PO fulfillment figures** — not yet filtered for `qty_mismatch_flag`; needs re-measurement with trustworthy-only data.

## 🎯 Flags Carried Into Step 2 (Diagnostic Analysis)

- Quantify seasonality effect as a % (not just visual spikes).
- Classify products as growing / declining / stable.
- Re-measure PO fulfillment gap using only trustworthy (non-flagged) rows.
- Re-measure stockout rate at the product level to remove the sampling-granularity bias.
- Investigate whether store-level stockouts can be approximated (data dictionary confirms no direct store-level stock tracking — see project README).
