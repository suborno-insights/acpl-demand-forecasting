# Step 3: Predictive Analysis — Findings

## Method

3-month-ahead revenue forecasts (Jan-Mar 2026) were built per category using
Facebook Prophet, with yearly seasonality enabled and weekly/daily
seasonality disabled (monthly-aggregated data has no sub-monthly pattern to
learn). Training data: 24 months (2024-01 to 2025-12), exported from SQL
Server as category-wise monthly revenue.

**Reliability was measured via backtesting**: a second model per category
was trained on only the first 21 months, then used to forecast the held-out
last 3 months (Oct-Dec 2025), which were then compared against the actual
known values. The resulting average error % is reported alongside each
forecast as a trust indicator — this is NOT the forecast's own error (which
can't be known yet), but a proxy based on how well the same method performed
on the most recent 3 known months.

## ⚠️ Known Limitation (flagged upfront)

Prophet's own diagnostics warned that yearly-seasonality decomposition may
be unstable with under 730 days (~24 months) of history — exactly our
situation. Each calendar month has only 1-2 historical examples for the
model to learn from. Grocery's backtest showed this concretely: October
error alone was +58.8% (vs. -8.6% and +7.4% for November/December),
pulling up its average. **Forecasts should be treated as directional
estimates, not precise targets** — this caveat applies most strongly to
categories with higher backtest error below.

## Forecast Summary (Jan-Mar 2026)

| Category | Jan 2026 | Feb 2026 | Mar 2026 | Backtest Avg Error % | Reliability |
|---|---|---|---|---|---|
| Stationery | ৳2,99,101 | ৳2,53,497 | ৳2,93,071 | 5.6% | 🟢 High |
| Electronics Accessories | ৳2,20,976 | ৳1,92,255 | ৳2,41,279 | 6.5% | 🟢 High |
| Beverages | ৳8,68,829 | ৳8,05,859 | ৳9,18,011 | 18.5% | 🟡 Moderate |
| Grocery | ৳31,11,239 | ৳27,26,929 | ৳33,11,674 | 19.2% | 🟡 Moderate |
| Personal Care | ৳7,85,630 | ৳7,27,753 | ৳8,51,976 | 23.6% | 🟠 Low |
| Footwear | ৳1,51,176 | ৳1,31,938 | ৳1,79,787 | 24.9% | 🟠 Low |
| Apparel | ৳2,18,876 | ৳1,99,823 | ৳2,18,266 | 25.4% | 🟠 Low |
| Home & Kitchen | ৳3,74,601 | ৳3,47,604 | ৳4,10,557 | 28.5% | 🔴 Low |

## Interpretation

- **Reliability varies substantially by category** (5.6% to 28.5% backtest
  error) — this is itself an important finding. A single blanket
  "trust the forecast" or "distrust the forecast" statement would be
  misleading; reliability needs to be communicated per category.
- **Grocery and Beverages** (the categories named in the original business
  problem) fall in the "Moderate" tier — useful as directional guidance for
  order planning, but not precise enough to set exact order quantities
  without a buffer margin.
- All 8 categories show a Jan → Feb dip → Mar rebound pattern in the
  forecast, consistent with Step 1/2's finding that Q1 is not a seasonal
  peak period (peaks are April/June/December).
- **Home & Kitchen's forecast carries the most uncertainty** — any
  Prescriptive recommendation using this category's numbers should include
  a wider safety margin than categories like Stationery or Electronics
  Accessories.

## Files

- `notebooks/01_demand_forecasting.ipynb` — full Prophet workflow (data
  load, model fit, forecast, backtest) for all 8 categories.
