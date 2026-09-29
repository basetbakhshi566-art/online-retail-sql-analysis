# Online Retail SQL Analysis

End-to-end SQL analysis of 541,909 e-commerce transactions (UCI Online Retail,
Dec 2010 – Dec 2011): from messy raw dump to trusted answers a sourcing
manager can act on.

**Author:** Baset Bakhshi — data analyst in training (Microsoft Data Analysis:
SQL · Excel · Power BI), founder of a product-sourcing agency. The questions
below are the ones I actually ask suppliers and customers every week.

## The four business questions

1. Which products sell best — by revenue *and* by units?
2. Which customers keep buying?
3. Which countries order most?
4. What drives revenue — and where is it at risk?

## What is in here

| File | What it is |
|---|---|
| `sql/01_build_clean.sql` | Raw → `clean_sales` (derived fields, line-type rules), `product_category` lookup table, reconciliation checks |
| `sql/02_business_queries.sql` | 8 saved business queries, each with a one-sentence purpose |
| `DATA_QUALITY.md` | Profiling results and every cleaning decision, documented |
| `FINDINGS.md` | The answers, with real numbers |
| `scripts/build_database.py` | Reproduces the whole database from the public dataset |

## How to run it

```bash
pip install openpyxl
python scripts/build_database.py      # downloads the dataset, builds online_retail.db
sqlite3 -header -column online_retail.db < sql/01_build_clean.sql
sqlite3 -header -column online_retail.db < sql/02_business_queries.sql
```

## SQL techniques demonstrated

Joins (product-category lookup) · CTEs · window functions (`RANK()`, `LAG()`,
running totals) · conditional aggregation · date truncation · a controlled
`CROSS JOIN` for share-of-total math · validation queries that reconcile raw
vs. cleaned totals.

## Three findings

1. **Revenue is product-diversified but geographically concentrated.** The top
   10 products are only 9.6% of £10.67M revenue — yet the UK alone is 84.6%.
2. **Repeat buyers are the engine.** 65.6% of customers placed more than one
   order; the most loyal customer placed 209.
3. **Q4 is the season that matters.** November 2011 hit £1.51M (+30.7% MoM);
   manual order adjustments (£146.8K cancelled value) deserve a process review.

Limitation: December 2011 covers only 9 days, so its −57.7% month-over-month
drop is a data artifact, not a collapse. 24.9% of lines have no CustomerID,
which bounds the customer analysis.

## Two-minute talk track

> "I took 541,000 messy retail transactions and made them trustworthy first —
> cancellations separated from sales, adjustments flagged, every rule written
> down. Then I answered four business questions in SQL. The headline: the
> business looks diversified by product but 85% of revenue comes from one
> country, two-thirds of customers buy repeatedly, and November is the month
> that makes the year. As someone who sources products, that tells me exactly
> where I'd focus: keep the repeat buyers, diversify markets, and stock up
> before Q4."
