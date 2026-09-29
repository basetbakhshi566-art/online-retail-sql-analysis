# Data-quality note

Profiling the raw table before any analysis. Every decision below is
implemented in `sql/01_build_clean.sql`.

## Profile (raw_sales, 541,909 rows)

| Check | Result |
|---|---|
| Distinct invoices | 25,900 |
| Distinct products (StockCode) | 4,070 |
| Distinct customers | 4,372 |
| Distinct countries | 38 |
| Missing CustomerID | 135,080 rows (24.9%) |
| Missing Description | 1,454 rows |
| Invoices starting with 'C' (cancellations) | 9,288 lines |
| Quantity ≤ 0 | 10,624 lines |
| UnitPrice ≤ 0 | 2,517 lines |
| Negative quantity on non-'C' invoices | 1,336 lines |
| Date range | 2010-12-01 → 2011-12-09 |
| Quantity range | −80,995 → 80,995 |
| UnitPrice range (£) | −11,062.06 → 38,970.00 |

## Decisions

1. **Line types.** `InvoiceNo LIKE 'C%'` → `cancellation`. Any other line with
   `Quantity <= 0` or `UnitPrice <= 0` → `adjustment` (bad-debt write-offs,
   samples, zero-price postage corrections). Everything else → `sale`.
   Result: 530,104 sales · 9,288 cancellations · 2,517 adjustments.
2. **Revenue** = `Quantity × UnitPrice`, meaningful only on `sale` lines.
   Total trusted sales revenue: **£10,666,684.54**.
3. **Cancellations stay visible** as their own measure (Q6) — never silently
   netted against sales.
4. **Anonymous lines kept** for product/country totals, **excluded** from
   customer-level analysis (no CustomerID to group by).
5. **One row per product.** The same StockCode ships with slightly different
   description spellings (even junk variants like 'Amazon' on one code), which
   tripled some revenue figures through join fan-out when grouping by
   description. Fixed two ways: `product_category` keeps one canonical
   description per StockCode (most frequent spelling), and product queries
   group by `StockCode`.
6. **Postage is not a product.** StockCodes `DOT`/`POST` (postage fees) are
   excluded from product rankings — they previously ranked #3 by "revenue".
7. **December 2011 is partial** (9 days). Month-over-month comparisons treat
   its −57.7% drop as a data artifact, documented in FINDINGS.md.
8. **Extreme values inspected, not auto-deleted.** The ±80,995 quantity pair
   is one bulk order and its cancellation; the £38,970 unit price sits on a
   `Manual` adjustment line.

## Validation

- Row count raw → clean: 541,909 → 541,909 (nothing dropped, only labelled).
- Sales revenue reconciles between the build script and the SQL checks.
