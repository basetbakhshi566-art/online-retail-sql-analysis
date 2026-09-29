# Findings — the eight answers

All numbers from `sql/02_business_queries.sql` on the cleaned table
(530,104 sale lines, £10,666,684.54 total revenue, Dec 2010 – Dec 2011).

## Q1a — Top products by revenue

| # | Product | Category | Revenue (£) |
|---|---|---|---|
| 1 | REGENCY CAKESTAND 3 TIER | Other | 174,484.74 |
| 2 | PAPER CRAFT, LITTLE BIRDIE | Other | 168,469.60 |
| 3 | CREAM HANGING HEART T-LIGHT HOLDER | Other | 104,518.80 |
| 4 | PARTY BUNTING | Other | 99,504.33 |
| 5 | JUMBO BAG RED RETROSPOT | Other | 94,340.05 |

## Q1b — Top products by units

| # | Product | Units | Revenue (£) |
|---|---|---|---|
| 1 | PAPER CRAFT, LITTLE BIRDIE | 80,995 | 168,469.60 |
| 2 | MEDIUM CERAMIC TOP STORAGE JAR | 78,033 | 81,700.92 |
| 3 | POPCORN HOLDER | 56,921 | 51,354.02 |
| 4 | WORLD WAR 2 GLIDERS ASSTD DESIGNS | 55,047 | 13,841.85 |
| 5 | JUMBO BAG RED RETROSPOT | 48,474 | 94,340.05 |

Takeaway: unit best-sellers ≠ revenue leaders (the #4 unit seller makes
£13.8K). Rank both, decide on both.

## Q2 — Repeat customers

- 4,338 customers placed orders; **2,845 (65.6%) ordered more than once.**
- Most frequent buyer: customer 12748 — **209 orders** (£33.7K).
- Highest-value repeat buyer in the top 20: customer 14646 — £280.2K over 73 orders.

## Q3 — Country performance

| Country | Orders | Customers | Revenue (£) | Share |
|---|---|---|---|---|
| United Kingdom | 18,019 | 3,920 | 9,025,222.08 | 84.6% |
| Netherlands | 94 | 9 | 285,446.34 | 2.7% |
| EIRE | 288 | 3 | 283,453.96 | 2.7% |
| Germany | 457 | 94 | 228,867.14 | 2.1% |
| France | 392 | 87 | 209,715.11 | 2.0% |

Takeaway: the business is a UK business with export sidelines — geographic
concentration is the #1 risk.

## Q4 — Monthly trend

Revenue climbs through 2011 with a clear Q4 peak: Sep £1.06M → Oct £1.15M →
**Nov £1.51M** (+30.7% MoM), then Dec £0.64M — but December covers only 9 days
of data, so that drop is an artifact.

## Q5 — Average order value

**£534.40** overall. Monthly AOV is stable (£430–£640) except Dec 2011
(£779.97 on the 9 recorded days — small-sample effect).

## Q6 — Cancellations

- Biggest cancellation value: `Manual` adjustment lines — 244 lines, **£146.8K**.
- Most-cancelled real product: REGENCY CAKESTAND 3 TIER — 181 lines (£9.7K).
- By country, the UK dominates cancellations (7,856 lines) simply because it
  dominates orders; EIRE's £20.2K cancelled value on 302 lines is worth a look.

## Q7 — Product mix (concentration)

The top 10 products together are **9.6% of revenue**. No single product can
sink the business — healthy diversification.

## Q8 — Month-over-month growth (window function)

Standout months: Mar 2011 **+37.1%**, May **+43.3%**, Sep **+39.4%**,
Nov **+30.7%**. The business roughly doubled its monthly run-rate from early
2011 (£0.5–0.7M) to Q4 (£1.1–1.5M).
