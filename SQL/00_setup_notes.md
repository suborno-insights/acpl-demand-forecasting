# SQL Setup Notes — Project 1: ACPL Demand Forecasting

## How the tables were actually created

Tables were **not** created via a `CREATE TABLE` + `BULK INSERT` script. That was
the original plan, but `BULK INSERT` repeatedly failed on the two largest files
(`purchase_orders`, `sales_transactions`) with a `"column too long"` error that
could not be traced to any actual issue in the CSV data (line endings, column
counts, and encoding were all verified clean). Switching `BULK INSERT` to
`FORMAT = 'CSV'` also failed, due to the "Ad Hoc Distributed Queries" server
option being disabled.

**Final approach**: SSMS's **Import Flat File** wizard, table by table.

## A data-corruption bug caught mid-import

The wizard's own type-sniffer (`Microsoft.SqlServer.Prose.Import`) repeatedly
mis-detected ID columns (`product_id`, `primary_supplier_id`, `supplier_id`) as
`money` or `numeric` instead of text. Because these columns held values like
`"P001"` and `"S006"`, the wizard's implicit conversion **silently stripped the
leading letter**, corrupting the data (`"P001"` became `1.00`).

This was caught by cross-checking imported values against the original CSVs
(the data dictionary process) — not by any error message, since the import
completed "successfully." Fix: re-run the import for the affected tables and
manually force those columns to `nvarchar(50)` on the wizard's "Modify Columns"
screen instead of trusting auto-detection.

**Lesson**: verify imported data against the source, even on a "successful"
import — a tool can complete without error and still corrupt data silently.

## A cleaning gap found (and fixed) during SQL analysis

Adding a Foreign Key from `purchase_orders.product_id` to `products.product_id`
failed on 53 rows with values like `"P009X"` — a trailing typo not caught during
the original Python cleaning pass. Verified that stripping the trailing `"X"`
from every affected value produced a real, existing `product_id`, confirming
this was a fixable typo (not a genuine unknown-product reference) and corrected
it with an `UPDATE` (`02_fix_purchase_orders_typo.sql`).

This is distinct from `sales_transactions.product_id = "P999"` (273 rows), which
*is* a genuine, intentional "unknown product" placeholder per the data
dictionary — not fixable, and left without a Foreign Key. Product-level
analysis uses `INNER JOIN` against `products`, which naturally excludes these
273 rows (0.09% of transactions).

## Column type corrections

The wizard defaults to `float` for decimal-looking numeric columns. All
currency, percentage, and quantity columns were converted to `DECIMAL(p,s)`
instead (`01_fix_float_to_decimal.sql`) to avoid floating-point rounding error
in aggregation — standard practice for financial data.
