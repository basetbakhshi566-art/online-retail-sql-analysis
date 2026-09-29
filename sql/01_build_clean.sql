-- ============================================================================
-- 01_build_clean.sql — Online Retail: from raw import to analysis-ready tables
-- Purpose: turn the raw transaction dump into one trusted sales table plus a
--          product-category lookup, with every cleaning rule stated explicitly.
-- Run after: scripts/build_database.py has loaded Online Retail.xlsx into
--            the raw_sales table (see README for the raw DDL).
-- Idempotent: drops and rebuilds derived tables.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Raw table (created by scripts/build_database.py — shown here for reference)
-- ----------------------------------------------------------------------------
-- CREATE TABLE raw_sales (
--   InvoiceNo   TEXT,   -- invoice number; cancellations start with 'C'
--   StockCode   TEXT,   -- product code
--   Description TEXT,   -- product description (1,454 rows missing)
--   Quantity    INTEGER,-- units; negative on cancellations/adjustments
--   InvoiceDate TEXT,   -- 'YYYY-MM-DD HH:MM:SS'
--   UnitPrice   REAL,   -- unit price in GBP; can be 0 or negative on adjustments
--   CustomerID  TEXT,   -- 135,080 rows (24.9%) have no customer
--   Country     TEXT
-- );

-- ----------------------------------------------------------------------------
-- Step 1: clean_sales — one row per transaction line, with derived fields
-- Cleaning rules (each documented in DATA_QUALITY.md):
--   1. line_type = 'cancellation' when InvoiceNo starts with 'C'.
--   2. line_type = 'adjustment' when Quantity <= 0 or UnitPrice <= 0 on any
--      other line (bad-debt write-offs, samples, zero-price postage lines).
--   3. Everything else is a 'sale' (Quantity > 0 AND UnitPrice > 0).
--   4. Revenue = Quantity * UnitPrice (meaningful only on 'sale' lines).
--   5. Anonymous lines (CustomerID IS NULL) are KEPT for product/country
--      totals but excluded from customer-level analysis in the queries.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS clean_sales;
CREATE TABLE clean_sales AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    DATE(InvoiceDate)            AS OrderDate,
    STRFTIME('%Y-%m', InvoiceDate) AS OrderMonth,
    UnitPrice,
    CustomerID,
    Country,
    Quantity * UnitPrice        AS Revenue,
    CASE
        WHEN InvoiceNo LIKE 'C%' THEN 'cancellation'
        WHEN Quantity <= 0 OR UnitPrice <= 0 THEN 'adjustment'
        ELSE 'sale'
    END                        AS line_type
FROM raw_sales;

CREATE INDEX IF NOT EXISTS idx_clean_month   ON clean_sales(OrderMonth);
CREATE INDEX IF NOT EXISTS idx_clean_country ON clean_sales(Country);
CREATE INDEX IF NOT EXISTS idx_clean_stock   ON clean_sales(StockCode);
CREATE INDEX IF NOT EXISTS idx_clean_cust    ON clean_sales(CustomerID);

-- ----------------------------------------------------------------------------
-- Step 2: product_category — my own business grouping of the 4,070 products
-- Purpose: demonstrate a lookup table + JOIN (a sourcing manager thinks in
--          categories, not 4,070 stock codes). Groups are assigned from
--          description keywords; anything unmatched lands in 'Other'.
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS product_category;
CREATE TABLE product_category AS
WITH ranked_desc AS (
    -- canonical description = the most frequent spelling per StockCode
    -- (MIN() is alphabetical and can pick a junk variant like 'Amazon')
    SELECT StockCode, Description,
           ROW_NUMBER() OVER (PARTITION BY StockCode
                              ORDER BY COUNT(*) DESC, Description) AS rn
    FROM clean_sales
    WHERE StockCode IS NOT NULL AND Description IS NOT NULL
    GROUP BY StockCode, Description
),
dedup AS (
    SELECT StockCode, Description FROM ranked_desc WHERE rn = 1
)
SELECT
    StockCode,
    Description,
    CASE
        WHEN UPPER(Description) LIKE '%CHRISTMAS%' THEN 'Seasonal'
        WHEN UPPER(Description) LIKE '%LAMP%'
          OR UPPER(Description) LIKE '%LANTERN%'
          OR UPPER(Description) LIKE '%CHANDELIER%'
          OR UPPER(Description) LIKE '%NIGHT LIGHT%'
          OR UPPER(Description) LIKE '%LIGHT%' THEN 'Lighting'
        WHEN UPPER(Description) LIKE '%MUG%'
          OR UPPER(Description) LIKE '%CUP%'
          OR UPPER(Description) LIKE '%PLATE%'
          OR UPPER(Description) LIKE '%BOWL%'
          OR UPPER(Description) LIKE '%TEAPOT%'
          OR UPPER(Description) LIKE '%KETTLE%'
          OR UPPER(Description) LIKE '%CUTLERY%'
          OR UPPER(Description) LIKE '%JUG%'
          OR UPPER(Description) LIKE '%TRAY%' THEN 'Kitchen & Dining'
        WHEN UPPER(Description) LIKE '%CUSHION%'
          OR UPPER(Description) LIKE '%THROW%'
          OR UPPER(Description) LIKE '%BLANKET%'
          OR UPPER(Description) LIKE '%TOWEL%'
          OR UPPER(Description) LIKE '%APRON%' THEN 'Textiles'
        WHEN UPPER(Description) LIKE '%NOTEBOOK%'
          OR UPPER(Description) LIKE '%PENCIL%'
          OR UPPER(Description) LIKE '%GIFT WRAP%'
          OR UPPER(Description) LIKE '%WRAPPING%' THEN 'Stationery & Craft'
        WHEN UPPER(Description) LIKE '%GARDEN%'
          OR UPPER(Description) LIKE '%PLANTER%' THEN 'Garden & Outdoor'
        WHEN UPPER(Description) LIKE '%DOLL%'
          OR UPPER(Description) LIKE '%TEDDY%'
          OR UPPER(Description) LIKE '%TOY%' THEN 'Toys & Games'
        WHEN UPPER(Description) LIKE '%DECOR%'
          OR UPPER(Description) LIKE '%ORNAMENT%'
          OR UPPER(Description) LIKE '%FRAME%'
          OR UPPER(Description) LIKE '%VASE%'
          OR UPPER(Description) LIKE '%MIRROR%' THEN 'Gifts & Decor'
        ELSE 'Other'
    END AS Category
FROM dedup;

-- ----------------------------------------------------------------------------
-- Step 3: validation — raw vs clean must reconcile (run and eyeball)
-- ----------------------------------------------------------------------------
-- Total rows preserved:
SELECT 'raw_rows'   AS check_name, COUNT(*) AS value FROM raw_sales
UNION ALL
SELECT 'clean_rows', COUNT(*) FROM clean_sales;

-- Line-type split:
SELECT line_type, COUNT(*) AS lines
FROM clean_sales
GROUP BY line_type
ORDER BY lines DESC;

-- Revenue reconciliation (sales only; cancellations/adjustments kept separate):
SELECT 'sales_revenue_gbp' AS check_name,
       ROUND(SUM(Revenue), 2) AS value
FROM clean_sales WHERE line_type = 'sale';
