-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- File: 03_product_analysis.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL
-- Module: Product Intelligence
-- ============================================================

/*
PURPOSE
-------
This module analyses product performance, profitability, category mix,
sales volume, pricing, returns, supplier exposure and product concentration.

BUSINESS QUESTIONS
------------------
01. Which products generate the most revenue?
02. Which products generate the most gross profit?
03. Which products have the highest gross margins?
04. Which products sell the most units?
05. Which products are underperforming?
06. Which categories generate the most revenue and profit?
07. Which categories have the highest margins?
08. How concentrated is revenue among top products?
09. What share of revenue comes from the Top 20 products?
10. Which products have the highest return rates?
11. What return reasons affect products most?
12. Which suppliers contribute the most revenue?
13. Which suppliers generate the most gross profit?
14. Which suppliers have the highest return exposure?
15. Which products have the largest discount impact?
16. Which products are inactive or discontinued?
17. How can products be grouped into value tiers?
18. What product-level reporting dataset can be used in Power BI?

NOTES
-----
Only Completed orders are treated as realised sales unless otherwise stated.

Gross Profit = Revenue - Product Cost

Gross Margin % = Gross Profit / Revenue

Return rate is calculated using returned order-item lines relative to
completed sold order-item lines.
*/


-- ============================================================
-- 01. TOP 20 PRODUCTS BY REVENUE
-- ============================================================
-- Business value:
-- Identifies the products contributing the highest realised sales value.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    s.supplier_name,

    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost),
        2
    ) AS gross_profit

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN suppliers s
    ON p.supplier_id = s.supplier_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name,
    s.supplier_name

ORDER BY revenue DESC
LIMIT 20;


-- ============================================================
-- 02. TOP 20 PRODUCTS BY GROSS PROFIT
-- ============================================================
-- Business value:
-- Identifies products that create the greatest economic contribution,
-- not just the highest sales value.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.quantity * oi.unit_cost),
        2
    ) AS cost,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(oi.quantity * oi.unit_cost)
        )
        / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS gross_margin_pct

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name

ORDER BY gross_profit DESC
LIMIT 20;


-- ============================================================
-- 03. TOP PRODUCTS BY GROSS MARGIN %
-- ============================================================
-- Business value:
-- Highlights products with the strongest profitability efficiency.
--
-- Minimum 50 units sold is applied to avoid misleading results
-- from low-volume products.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    SUM(oi.quantity) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(oi.quantity * oi.unit_cost)
        )
        / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS gross_margin_pct

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name

HAVING SUM(oi.quantity) >= 50

ORDER BY gross_margin_pct DESC
LIMIT 20;


-- ============================================================
-- 04. TOP 20 PRODUCTS BY UNITS SOLD
-- ============================================================
-- Business value:
-- Identifies high-volume products and operational demand drivers.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    SUM(oi.quantity) AS units_sold,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name

ORDER BY units_sold DESC
LIMIT 20;


-- ============================================================
-- 05. LOWEST-PERFORMING PRODUCTS BY REVENUE
-- ============================================================
-- Business value:
-- Identifies products with weak commercial contribution that may
-- require pricing, promotion, assortment or discontinuation review.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    SUM(oi.quantity) AS units_sold,

    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name

ORDER BY revenue ASC
LIMIT 20;


-- ============================================================
-- 06. CATEGORY PERFORMANCE
-- ============================================================
-- Business value:
-- Compares category revenue, profit, margin, order activity
-- and units sold.

SELECT
    c.category_name,

    COUNT(DISTINCT p.product_id) AS products,

    COUNT(DISTINCT o.order_id) AS orders,

    SUM(oi.quantity) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(oi.quantity * oi.unit_cost)
        )
        / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS gross_margin_pct

FROM categories c

JOIN products p
    ON c.category_id = p.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY c.category_name
ORDER BY revenue DESC;


-- ============================================================
-- 07. CATEGORY REVENUE SHARE
-- ============================================================
-- Business value:
-- Measures how dependent total company revenue is on each category.

SELECT
    c.category_name,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        100.0 *
        SUM(oi.line_revenue)
        / NULLIF(
            SUM(SUM(oi.line_revenue)) OVER (),
            0
        ),
        2
    ) AS revenue_share_pct

FROM categories c

JOIN products p
    ON c.category_id = p.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY c.category_name
ORDER BY revenue DESC;


-- ============================================================
-- 08. PRODUCT REVENUE CONCENTRATION
-- ============================================================
-- Business value:
-- Shows each product's share of total revenue and highlights
-- concentration risk among leading SKUs.

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.line_revenue) AS revenue

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name
)

SELECT
    product_id,
    product_name,

    ROUND(revenue, 2) AS revenue,

    ROUND(
        100.0 *
        revenue
        / NULLIF(SUM(revenue) OVER (), 0),
        4
    ) AS revenue_share_pct

FROM product_revenue
ORDER BY revenue DESC;


-- ============================================================
-- 09. TOP 20 PRODUCTS REVENUE CONTRIBUTION
-- ============================================================
-- Business value:
-- Quantifies how much total revenue is generated by the
-- 20 highest-revenue products.

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.line_revenue) AS revenue

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name
),

ranked AS (
    SELECT
        product_id,
        product_name,
        revenue,

        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS product_rank,

        SUM(revenue) OVER () AS total_revenue

    FROM product_revenue
)

SELECT
    COUNT(*) AS top_20_products,

    ROUND(
        SUM(revenue),
        2
    ) AS top_20_revenue,

    ROUND(
        MAX(total_revenue),
        2
    ) AS total_revenue,

    ROUND(
        100.0 *
        SUM(revenue)
        / NULLIF(MAX(total_revenue), 0),
        2
    ) AS top_20_revenue_share_pct

FROM ranked

WHERE product_rank <= 20;


-- ============================================================
-- 10. PRODUCT RETURN RATE
-- ============================================================
-- Business value:
-- Identifies products with unusually high return activity,
-- which may indicate quality, expectation or fulfilment problems.

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,

        COUNT(oi.order_item_id) AS sold_order_lines,

        SUM(oi.quantity) AS units_sold

    FROM products p

    JOIN categories c
        ON p.category_id = c.category_id

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name,
        c.category_name
),

product_returns AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT r.return_id) AS returned_lines,
        ROUND(
            SUM(r.refund_amount),
            2
        ) AS refund_amount

    FROM returns r

    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id

    WHERE r.return_status = 'Approved'

    GROUP BY oi.product_id
)

SELECT
    ps.product_id,
    ps.product_name,
    ps.category_name,
    ps.sold_order_lines,
    ps.units_sold,

    COALESCE(pr.returned_lines, 0) AS returned_lines,

    COALESCE(pr.refund_amount, 0) AS refund_amount,

    ROUND(
        100.0 *
        COALESCE(pr.returned_lines, 0)
        / NULLIF(ps.sold_order_lines, 0),
        2
    ) AS return_rate_pct

FROM product_sales ps

LEFT JOIN product_returns pr
    ON ps.product_id = pr.product_id

ORDER BY return_rate_pct DESC,
         returned_lines DESC;


-- ============================================================
-- 11. RETURN REASONS BY PRODUCT CATEGORY
-- ============================================================
-- Business value:
-- Identifies the main causes of returns by category and supports
-- product quality or fulfilment improvement initiatives.

SELECT
    c.category_name,
    r.return_reason,

    COUNT(*) AS returns,

    ROUND(
        SUM(r.refund_amount),
        2
    ) AS refund_amount

FROM returns r

JOIN order_items oi
    ON r.order_item_id = oi.order_item_id

JOIN products p
    ON oi.product_id = p.product_id

JOIN categories c
    ON p.category_id = c.category_id

WHERE r.return_status = 'Approved'

GROUP BY
    c.category_name,
    r.return_reason

ORDER BY
    c.category_name,
    returns DESC;


-- ============================================================
-- 12. SUPPLIER PERFORMANCE BY REVENUE
-- ============================================================
-- Business value:
-- Shows which suppliers support the largest amount of commercial
-- product revenue.

SELECT
    s.supplier_id,
    s.supplier_name,
    r.country AS supplier_country,
    s.quality_score,

    COUNT(DISTINCT p.product_id) AS products,

    SUM(oi.quantity) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM suppliers s

JOIN regions r
    ON s.region_id = r.region_id

JOIN products p
    ON s.supplier_id = p.supplier_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    s.supplier_id,
    s.supplier_name,
    r.country,
    s.quality_score

ORDER BY revenue DESC;


-- ============================================================
-- 13. SUPPLIER PROFITABILITY
-- ============================================================
-- Business value:
-- Identifies supplier portfolios contributing most to gross profit.

SELECT
    s.supplier_id,
    s.supplier_name,
    s.quality_score,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(oi.quantity * oi.unit_cost)
        )
        / NULLIF(SUM(oi.line_revenue), 0),
        2
    ) AS gross_margin_pct

FROM suppliers s

JOIN products p
    ON s.supplier_id = p.supplier_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.quality_score

ORDER BY gross_profit DESC;


-- ============================================================
-- 14. SUPPLIER RETURN EXPOSURE
-- ============================================================
-- Business value:
-- Identifies suppliers whose products generate the greatest number
-- of approved returns and refund value.

SELECT
    s.supplier_id,
    s.supplier_name,

    COUNT(DISTINCT r.return_id) AS approved_returns,

    ROUND(
        SUM(r.refund_amount),
        2
    ) AS refund_amount

FROM suppliers s

JOIN products p
    ON s.supplier_id = p.supplier_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN returns r
    ON oi.order_item_id = r.order_item_id

WHERE r.return_status = 'Approved'

GROUP BY
    s.supplier_id,
    s.supplier_name

ORDER BY refund_amount DESC;


-- ============================================================
-- 15. DISCOUNT IMPACT BY PRODUCT
-- ============================================================
-- Business value:
-- Identifies products where discounting has the greatest commercial
-- impact and supports pricing optimisation.

SELECT
    p.product_id,
    p.product_name,
    c.category_name,

    SUM(oi.quantity) AS units_sold,

    ROUND(
        AVG(oi.discount_pct) * 100,
        2
    ) AS avg_discount_pct,

    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        ),
        2
    ) AS gross_value_before_discount,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS net_revenue,

    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        )
        - SUM(oi.line_revenue),
        2
    ) AS estimated_discount_value

FROM products p

JOIN categories c
    ON p.category_id = c.category_id

JOIN order_items oi
    ON p.product_id = oi.product_id

JOIN orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    p.product_id,
    p.product_name,
    c.category_name

ORDER BY estimated_discount_value DESC
LIMIT 20;


-- ============================================================
-- 16. PRODUCT CATALOGUE STATUS
-- ============================================================
-- Business value:
-- Reviews current catalogue status and identifies discontinued
-- products that still generated historical revenue.

SELECT
    p.status,

    COUNT(*) AS products,

    ROUND(
        AVG(p.list_price),
        2
    ) AS avg_list_price,

    ROUND(
        AVG(p.unit_cost),
        2
    ) AS avg_unit_cost

FROM products p

GROUP BY p.status
ORDER BY products DESC;


-- ============================================================
-- 17. PRODUCT VALUE TIERS
-- ============================================================
-- Business value:
-- Segments products into quartiles based on revenue contribution.
-- This can support assortment planning and category management.

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,

        SUM(oi.quantity) AS units_sold,

        SUM(oi.line_revenue) AS revenue,

        SUM(oi.line_revenue)
        - SUM(oi.quantity * oi.unit_cost) AS gross_profit

    FROM products p

    JOIN categories c
        ON p.category_id = c.category_id

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name,
        c.category_name
),

tiered AS (
    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY revenue DESC
        ) AS value_quartile

    FROM product_metrics
)

SELECT
    product_id,
    product_name,
    category_name,
    units_sold,

    ROUND(revenue, 2) AS revenue,

    ROUND(gross_profit, 2) AS gross_profit,

    CASE
        WHEN value_quartile = 1
            THEN 'Tier 1 - High Value'

        WHEN value_quartile = 2
            THEN 'Tier 2 - Upper Mid Value'

        WHEN value_quartile = 3
            THEN 'Tier 3 - Lower Mid Value'

        ELSE 'Tier 4 - Low Value'
    END AS product_value_tier

FROM tiered

ORDER BY revenue DESC;


-- ============================================================
-- 18. PRODUCT BI SUMMARY DATASET
-- ============================================================
-- Business value:
-- Creates a reporting-ready product-level analytical dataset
-- suitable for a PostgreSQL VIEW and Power BI.

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.status,

        c.category_name,

        s.supplier_id,
        s.supplier_name,
        s.quality_score,

        COUNT(DISTINCT o.order_id) AS completed_orders,

        SUM(oi.quantity) AS units_sold,

        SUM(oi.line_revenue) AS revenue,

        SUM(
            oi.quantity * oi.unit_cost
        ) AS cost,

        AVG(oi.discount_pct) AS avg_discount_pct,

        MIN(o.order_date) AS first_sale_date,

        MAX(o.order_date) AS last_sale_date

    FROM products p

    JOIN categories c
        ON p.category_id = c.category_id

    JOIN suppliers s
        ON p.supplier_id = s.supplier_id

    LEFT JOIN order_items oi
        ON p.product_id = oi.product_id

    LEFT JOIN orders o
        ON oi.order_id = o.order_id
       AND o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name,
        p.status,
        c.category_name,
        s.supplier_id,
        s.supplier_name,
        s.quality_score
),

product_returns AS (
    SELECT
        oi.product_id,

        COUNT(DISTINCT r.return_id) FILTER (
            WHERE r.return_status = 'Approved'
        ) AS approved_returns,

        COALESCE(
            SUM(r.refund_amount) FILTER (
                WHERE r.return_status = 'Approved'
            ),
            0
        ) AS refund_amount

    FROM order_items oi

    LEFT JOIN returns r
        ON oi.order_item_id = r.order_item_id

    GROUP BY oi.product_id
)

SELECT
    ps.product_id,
    ps.product_name,
    ps.category_name,

    ps.supplier_id,
    ps.supplier_name,
    ps.quality_score,

    ps.status AS product_status,

    ps.first_sale_date,
    ps.last_sale_date,

    ps.completed_orders,

    COALESCE(ps.units_sold, 0) AS units_sold,

    ROUND(
        COALESCE(ps.revenue, 0),
        2
    ) AS revenue,

    ROUND(
        COALESCE(ps.cost, 0),
        2
    ) AS cost,

    ROUND(
        COALESCE(ps.revenue, 0)
        - COALESCE(ps.cost, 0),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            COALESCE(ps.revenue, 0)
            - COALESCE(ps.cost, 0)
        )
        / NULLIF(ps.revenue, 0),
        2
    ) AS gross_margin_pct,

    ROUND(
        COALESCE(ps.avg_discount_pct, 0) * 100,
        2
    ) AS avg_discount_pct,

    COALESCE(pr.approved_returns, 0) AS approved_returns,

    ROUND(
        COALESCE(pr.refund_amount, 0),
        2
    ) AS refund_amount,

    ROUND(
        100.0 *
        COALESCE(pr.approved_returns, 0)
        / NULLIF(ps.completed_orders, 0),
        2
    ) AS return_to_order_pct

FROM product_sales ps

LEFT JOIN product_returns pr
    ON ps.product_id = pr.product_id

ORDER BY revenue DESC;


