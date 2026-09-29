-- ============================================================================
-- 02_business_queries.sql — eight sourcing questions, answered in SQL
-- Conventions: 'sale' lines only unless stated; a "completed order" is a
-- distinct InvoiceNo with at least one sale line; revenue is in GBP.
-- Each query carries a one-sentence purpose. Run in order with sqlite3:
--   sqlite3 -header -column online_retail.db < sql/02_business_queries.sql
-- ============================================================================

-- Q1a. PURPOSE: rank products by revenue — what actually makes the money?
-- Top 20 products by revenue (sale lines), with units sold and category.
-- Grouped by StockCode (descriptions vary in spelling for the same code);
-- postage fees ('DOT','POST') are excluded — they are charges, not products.
WITH ranked AS (
    SELECT s.StockCode,
           MIN(s.Description) AS Description,
           MIN(pc.Category)   AS Category,
           SUM(s.Quantity) AS units_sold,
           ROUND(SUM(s.Revenue), 2) AS revenue_gbp
    FROM clean_sales s
    LEFT JOIN product_category pc ON pc.StockCode = s.StockCode
    WHERE s.line_type = 'sale'
      AND s.StockCode NOT IN ('DOT', 'POST')
    GROUP BY s.StockCode
)
SELECT Description, Category, units_sold, revenue_gbp,
       RANK() OVER (ORDER BY revenue_gbp DESC) AS revenue_rank
FROM ranked
ORDER BY revenue_gbp DESC
LIMIT 20;

-- Q1b. PURPOSE: rank products by units — best-sellers are not always the
-- most profitable; compare this list with Q1a.
WITH ranked AS (
    SELECT s.StockCode,
           MIN(s.Description) AS Description,
           SUM(s.Quantity) AS units_sold,
           ROUND(SUM(s.Revenue), 2) AS revenue_gbp
    FROM clean_sales s
    WHERE s.line_type = 'sale'
      AND s.StockCode NOT IN ('DOT', 'POST')
    GROUP BY s.StockCode
)
SELECT Description, units_sold, revenue_gbp,
       RANK() OVER (ORDER BY units_sold DESC) AS units_rank
FROM ranked
ORDER BY units_sold DESC
LIMIT 20;

-- Q2. PURPOSE: find repeat customers — who keeps coming back, and who is
-- worth retaining? (Anonymous lines excluded: no CustomerID to group by.)
WITH cust AS (
    SELECT CustomerID,
           COUNT(DISTINCT InvoiceNo) AS orders_placed,
           ROUND(SUM(Revenue), 2)    AS revenue_gbp
    FROM clean_sales
    WHERE line_type = 'sale' AND CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT InvoiceNo) > 1
)
SELECT CustomerID, orders_placed, revenue_gbp,
       RANK() OVER (ORDER BY orders_placed DESC, revenue_gbp DESC) AS loyalty_rank
FROM cust
ORDER BY orders_placed DESC, revenue_gbp DESC
LIMIT 20;

-- Q2b. PURPOSE: headline repeat-buyer stats for the summary.
SELECT
    COUNT(DISTINCT CustomerID) AS customers_with_orders,
    SUM(CASE WHEN order_cnt > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_cnt > 1 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS repeat_rate_pct
FROM (
    SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS order_cnt
    FROM clean_sales
    WHERE line_type = 'sale' AND CustomerID IS NOT NULL
    GROUP BY CustomerID
);

-- Q3. PURPOSE: compare countries on orders, customers, units and revenue —
-- where should a sourcing agent focus market effort?
SELECT Country,
       COUNT(DISTINCT InvoiceNo)          AS orders,
       COUNT(DISTINCT CustomerID)         AS customers,
       SUM(Quantity)                     AS units,
       ROUND(SUM(Revenue), 2)            AS revenue_gbp,
       ROUND(SUM(Revenue) * 100.0 /
             SUM(SUM(Revenue)) OVER (), 1) AS revenue_share_pct
FROM clean_sales
WHERE line_type = 'sale'
GROUP BY Country
ORDER BY revenue_gbp DESC
LIMIT 15;

-- Q4. PURPOSE: monthly trend — is the business growing, seasonal, or flat?
SELECT OrderMonth,
       ROUND(SUM(Revenue), 2)     AS revenue_gbp,
       COUNT(DISTINCT InvoiceNo)  AS orders
FROM clean_sales
WHERE line_type = 'sale'
GROUP BY OrderMonth
ORDER BY OrderMonth;

-- Q5. PURPOSE: average order value — the single number behind "how much
-- does a typical order bring in?", plus the monthly view for context.
SELECT ROUND(SUM(Revenue) * 1.0 /
             COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value_gbp
FROM clean_sales
WHERE line_type = 'sale';

SELECT OrderMonth,
       ROUND(SUM(Revenue) * 1.0 / COUNT(DISTINCT InvoiceNo), 2) AS aov_gbp
FROM clean_sales
WHERE line_type = 'sale'
GROUP BY OrderMonth
ORDER BY OrderMonth;

-- Q6a. PURPOSE: which products get cancelled most — quality or listing issue?
SELECT MIN(Description) AS Description,
       COUNT(*) AS cancelled_lines,
       ROUND(ABS(SUM(Revenue)), 2) AS cancelled_value_gbp
FROM clean_sales
WHERE line_type = 'cancellation'
GROUP BY StockCode
ORDER BY cancelled_lines DESC
LIMIT 15;

-- Q6b. PURPOSE: cancellations by country — where do orders fall through?
SELECT Country,
       COUNT(*) AS cancelled_lines,
       ROUND(ABS(SUM(Revenue)), 2) AS cancelled_value_gbp
FROM clean_sales
WHERE line_type = 'cancellation'
GROUP BY Country
ORDER BY cancelled_lines DESC
LIMIT 10;

-- Q7. PURPOSE: revenue concentration — how much of the business rides on
-- the top 10 products? (High concentration = sourcing risk.)
WITH prod AS (
    SELECT StockCode,
           MIN(Description) AS Description,
           ROUND(SUM(Revenue), 2) AS revenue_gbp
    FROM clean_sales
    WHERE line_type = 'sale'
      AND StockCode NOT IN ('DOT', 'POST')
    GROUP BY StockCode
),
total AS (SELECT SUM(revenue_gbp) AS total_gbp FROM prod)
SELECT p.Description, p.revenue_gbp,
       ROUND(p.revenue_gbp * 100.0 / t.total_gbp, 2) AS share_pct,
       ROUND(SUM(p.revenue_gbp) OVER (ORDER BY p.revenue_gbp DESC) * 100.0
             / t.total_gbp, 2) AS running_share_pct
FROM prod p CROSS JOIN total t
ORDER BY p.revenue_gbp DESC
LIMIT 10;

-- Q8. PURPOSE: month-over-month revenue growth with a window function —
-- no collapsing the detail before the comparison is made.
WITH monthly AS (
    SELECT OrderMonth, ROUND(SUM(Revenue), 2) AS revenue_gbp
    FROM clean_sales
    WHERE line_type = 'sale'
    GROUP BY OrderMonth
)
SELECT OrderMonth,
       revenue_gbp,
       LAG(revenue_gbp) OVER (ORDER BY OrderMonth) AS prev_month_gbp,
       ROUND((revenue_gbp - LAG(revenue_gbp) OVER (ORDER BY OrderMonth)) * 100.0
             / LAG(revenue_gbp) OVER (ORDER BY OrderMonth), 1) AS mom_growth_pct
FROM monthly
ORDER BY OrderMonth;
