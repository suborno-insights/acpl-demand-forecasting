# ACPL Demand Forecasting & Inventory Signal Analysis

Project 1 of a 6-project data analytics portfolio series built around **Apex Consumer Products Ltd. (ACPL)** — a fictional Bangladeshi retail chain with 20 stores, 3 warehouses, 45 suppliers, and ~6,000 customers.

## 📊 Business Problem

Over the last 2 quarters, ACPL's management has observed recurring stockouts in the **Grocery** and **Beverages** categories at several stores, while some warehouses simultaneously carry overstock. The company has no data-driven forecasting system in place — ordering decisions are currently made purely on gut feeling, with no visibility into demand trends, seasonality, or the gap between what's ordered and what's actually sold.

## 🎯 Business Questions

1. What was the category-wise sales trend over the last 24 months?
2. How much does seasonality (Eid, year-end, Boishakh) affect demand, in percentage terms?
3. Which specific products are growing, declining, or stable?
4. What is the gap between current ordering patterns and actual demand?
5. What might demand look like over the next 3 months?

## 👥 Decision-Maker Impact

- **Category Manager** — can adjust order quantities per product/category based on evidence rather than intuition
- **Finance Team** — can plan monthly cash/budget needs using demand projections

## 🛠️ Tools Used

- **SQL** — data extraction, aggregation, KPI queries
- **Python** (pandas, statsmodels/Prophet) — diagnostic analysis and time-series forecasting
- **Power BI / Tableau** — dashboards for descriptive and prescriptive views
- **Excel** — quick checks and stakeholder-facing summaries

## 🧭 Analysis Framework

This project follows a 4-step framework, moving from what happened to what should be done next:

| Step | Question | Method |
|---|---|---|
| **Descriptive** | What happened? | Aggregation, trend charts, category/store-level summaries |
| **Diagnostic** | Why did it happen? | Seasonality breakdown, YoY/MoM comparison, order-vs-demand gap analysis |
| **Predictive** | What might happen next? | Time-series forecasting (Prophet/statsmodels), trend + seasonality decomposition |
| **Prescriptive** | What should be done? | Threshold-based order recommendations, dashboard, written action plan |

## ✅ Progress

- [x] **Step 1: Descriptive Analysis** — see [`reports/01_descriptive_findings.md`](reports/01_descriptive_findings.md) for full findings. Key results: baseline of ~৳12.9 crore revenue over 24 months; synchronized seasonal spikes across all categories (April/June/December); Grocery dominates demand volume; ~96.25% PO fulfillment and ~15–16% stockout rate, both consistent across all 3 warehouses.
- [x] **Step 2: Diagnostic Analysis** — see [`reports/02_diagnostic_findings.md`](reports/02_diagnostic_findings.md) for full findings. Seasonality lift empirically confirmed at ~30-34% across all categories (peak months validated via z-score, not assumed); products classified as Growing (83) / Stable (41) / Declining (24) / Never Sold (32); root cause of the order-vs-demand gap found — order size/frequency per product is largely independent of actual demand (routine ordering, not data-driven), the single most actionable finding for Step 4. Also resolved 3 data-quality caveats flagged in Step 1: corrected PO fulfillment (~97.5%, up from a data-quality-distorted 96.25%), corrected stockout rate split by product sampling group (13.4% general catalog vs 17.6% risk-linked), and built a store-level stockout proxy using shipment delay/loss rate (added the `shipments` table specifically for this).
- [ ] Step 3: Predictive Analysis
- [ ] Step 4: Prescriptive Analysis

## 📁 Project Structure

```
acpl-demand-forecasting/
├── data/
│   ├── raw/                          # cleaned CSVs (sourced from acpl-data-cleaning)
│   └── data_dictionary.md
├── sql/
│   ├── 00_setup_notes.md             # wizard-import corruption bug + typo-fix journey
│   ├── 01_fix_float_to_decimal.sql
│   ├── 02_fix_purchase_orders_typo.sql
│   ├── 03_foreign_keys.sql
│   ├── 04_descriptive_analysis.sql   # Step 1 queries
│   ├── 05_diagnostic_analysis.sql    # Step 2 queries
│   └── 06_shipments_setup.sql        # shipments table added for Step 2 Investigation #6
├── notebooks/
├── dashboards/
└── reports/
    ├── 01_descriptive_findings.md    # Step 1 findings + flags for Step 2
    └── 02_diagnostic_findings.md     # Step 2 findings
```

## 🔗 Related Repositories

- [acpl-data-cleaning](#) — full documentation of the data cleaning process for this dataset

---
*Part of a 6-project analytics portfolio series based on ACPL. This is Project 1 of 6.*
