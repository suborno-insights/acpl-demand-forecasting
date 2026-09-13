# Step 2: Diagnostic Analysis — Findings

All core business questions and carried-forward investigations complete.

## 📈 Seasonality Effect

Peak months (April, June, December) were empirically validated per category
using z-scores against each category's own 24-month average — not assumed.
All 8 categories showed their top-3 z-score months within this same Apr/Jun/Dec
set, confirming this is a genuine company-wide pattern (Boishakh, Eid al-Adha,
year-end), not a category-specific coincidence.

**Seasonal lift by category** (peak-month average vs non-peak-month average):

| Category | % Lift |
|---|---|
| Stationery | 34.3% |
| Apparel | 33.3% |
| Home & Kitchen | 32.8% |
| Grocery | 32.5% |
| Personal Care | 31.9% |
| Beverages | 30.9% |
| Electronics Accessories | 30.2% |
| Footwear | 29.8% |

**Takeaway**: seasonality lift is remarkably uniform across categories (~30-34%).
A single company-wide "increase peak-month orders by ~30%" rule of thumb is
reasonable rather than needing category-specific seasonal models.

## 📊 Product Growth Classification (YoY, 2024 vs 2025, units-based)

| Classification | Product Count | % of Portfolio | Total Units 2024 | Total Units 2025 |
|---|---|---|---|---|
| Growing | 83 | 46.1% | 166,342 | 213,836 |
| Stable | 41 | 22.8% | 72,007 | 73,823 |
| Never Sold | 32 | 17.8% | 0 | 0 |
| Declining | 24 | 13.3% | 27,751 | 21,479 |

Notes:
- Ranking used **units sold**, not revenue — revenue mixes price and volume,
  and stockout risk is a volume problem.
- "Never Sold" (32 products) matches exactly the 32 inactive products found
  in Step 1's portfolio mix check — confirms data consistency.
- No products fell into "New" or "Discontinued" (a mid-period launch/exit) —
  the never-sold products appear inactive for the full 24-month window rather
  than transitioning partway through.
- 46% of the portfolio is growing (units up ~29% YoY); 13.3% is declining
  (units down ~23% YoY) — these declining products are candidates for reduced
  ordering.

## 🔍 Order vs Actual Demand Gap — Root Cause

Product-wise comparison of total `purchase_orders.order_qty` vs total
`sales_transactions.quantity` shows extreme, widespread over-ordering —
gaps ranging from ~30% up to over 13,000% for some products.

**Ruled out**: `qty_mismatch_flag` rate does not correlate with gap size
(flagged-PO rate is ~8-11% regardless of whether a product has a small or
enormous gap) — this is not a data-quality artifact.

**Root cause found**: order size and order frequency per product are
**largely independent of actual demand**. Example:

| Product | Total Sold (2yr) | PO Count | Avg Order Size/PO |
|---|---|---|---|
| P040 (highest-demand Grocery item) | ~10,266/yr | 213 | 412.5 |
| P065 (lowest-demand item, 637 units total in 2 years) | 637 | 220 | 387.7 |

Despite roughly a 30x difference in actual demand, both products receive
almost the same number of orders (~213-220) at almost the same average size
(~390-410 units) — consistent with the business problem statement that
ordering is done by "gut feeling" rather than being demand-driven. This is
likely both the cause of overstock (low-demand products massively
over-ordered) and a contributing factor to stockouts during demand spikes
that a fixed routine order size can't absorb.

**Two isolated anomalies noted, not further investigated** (negligible
volume): products P009 and P099 were ordered (1,750 and 965 units
respectively) but never sold at all — likely discontinued before any sale
occurred.

## ✅ Carried-Forward Investigations (from Step 1 flags)

### Investigation #4: PO Fulfillment — Trustworthy-only Recheck

The original ~96.25% fulfillment figure included `purchase_orders` rows
flagged `qty_mismatch_flag=1` (incomplete/inconsistent `qty_received`
records, per the cleaning log — mostly rows with missing `qty_rejected`).

| Warehouse | Fulfillment % (all rows) | Fulfillment % (trustworthy only) |
|---|---|---|
| W01 – Dhaka Central DC | 96.26% | 97.55% |
| W02 – Chattogram Regional DC | 96.28% | 97.54% |
| W03 – Rajshahi Regional DC | 96.26% | 97.54% |

The flagged rows disproportionately included low/incomplete `qty_received`
values, dragging down the blended figure. **Corrected fulfillment rate:
~97.5%**, uniform across warehouses — this is the more reliable number for
reporting.

### Investigation #5: Stockout Rate — Product-level Breakdown

Split by `inventory_snapshots.snapshot_granularity` to remove the sampling
bias from ~20 risk-linked products getting daily snapshots vs. weekly for
the rest:

| Group | Product Count | Stockout % |
|---|---|---|
| Daily-tracked (risk-linked) | 20 | 17.61% |
| Weekly-tracked (rest of catalog) | 128 | 13.40% |

(20 + 128 = 148 matches the "has sales history" product count from Step 2's
growth classification — consistency check passed.) The blended ~15-16%
figure from Step 1 was skewed toward the risk-linked group because daily
sampling produces far more snapshot rows per product. **Corrected: general
catalog stockout rate ~13.4%; risk-linked products run somewhat higher at
~17.6%** — both should be reported separately, not blended.

### Investigation #6: Store-level Stockout Proxy (via Shipment Risk)

No direct store-level stock quantity exists in this dataset (inventory is
tracked at the warehouse level only). As a supply-side proxy, the `%` of
each store's inbound shipments with `shipment_status` of Delayed or Lost
was used — added the `shipments` table specifically for this investigation
(see `sql/06_shipments_setup.sql`; not part of the original 7-table scope).

33 shipment rows reference `store_id = 'ST99'`, a genuine invalid
placeholder (already flagged by a pre-existing `store_id_invalid_flag`
column from the original cleaning) — excluded via `INNER JOIN`, same
treatment as `sales_transactions`' "P999".

Risk % ranged from 17.9% (ST15) to 24.9% (ST19) across the 20 stores — a
continuous spread, no extreme outlier. A mild regional pattern: Khulna's two
stores (23.4%, 24.9%) sit at the higher end, Chattogram's stores at the
lower end, though the per-region sample is small (2-4 stores) so this is
directional, not conclusive. No clear relationship with `store_type`
(Flagship/Standard/Express) was found — risk is spread across all types.

**Practical use**: since direct store-level stockout data isn't available,
this shipment-risk ranking is the best available proxy for prioritizing
which stores might need extra safety-stock buffer.

## 🎯 Direction for Step 4 (Prescriptive)

The order-size/demand-independence finding is likely the single most
actionable insight in this project: ACPL needs demand-based dynamic
ordering (scaled per product to actual/forecasted demand) rather than a
routine fixed-quantity ordering pattern.
