-- SQL Business Intelligence Project
-- File: 01_sales_analysis.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL

-- 01. Executive KPI Summary
SELECT
    ROUND(SUM(oi.line_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS total_cost,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    ROUND(100.0 * (SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost)) / NULLIF(SUM(oi.line_revenue), 0), 2) AS gross_margin_pct,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed';

-- 02. Annual Sales Performance
SELECT
    EXTRACT(YEAR FROM o.order_date)::INT AS sales_year,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY EXTRACT(YEAR FROM o.order_date)
ORDER BY sales_year;

-- 03. Monthly Sales Trend
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY sales_month;

-- 04. Sales by Market
SELECT
    r.market,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(100.0 * SUM(oi.line_revenue) / SUM(SUM(oi.line_revenue)) OVER (), 2) AS revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN regions r ON o.region_id = r.region_id
WHERE o.order_status = 'Completed'
GROUP BY r.market
ORDER BY revenue DESC;

-- 05. Sales by Country
SELECT
    r.country,
    r.market,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN regions r ON o.region_id = r.region_id
WHERE o.order_status = 'Completed'
GROUP BY r.country, r.market
ORDER BY revenue DESC;

-- 06. Sales by Channel
SELECT
    o.sales_channel,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value,
    ROUND(100.0 * SUM(oi.line_revenue) / SUM(SUM(oi.line_revenue)) OVER (), 2) AS revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.sales_channel
ORDER BY revenue DESC;

-- 07. Category Performance
SELECT
    c.category_name,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    ROUND(100.0 * (SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost)) / NULLIF(SUM(oi.line_revenue), 0), 2) AS gross_margin_pct,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY c.category_name
ORDER BY revenue DESC;

-- 08. Top 20 Products by Revenue
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY revenue DESC
LIMIT 20;

-- 09. Top 20 Products by Gross Profit
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(100.0 * (SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost)) / NULLIF(SUM(oi.line_revenue), 0), 2) AS gross_margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY gross_profit DESC
LIMIT 20;

-- 10. Year-over-Year Revenue Growth
WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date)::INT AS sales_year,
        SUM(oi.line_revenue) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM o.order_date)
), growth AS (
    SELECT
        sales_year,
        revenue,
        LAG(revenue) OVER (ORDER BY sales_year) AS previous_year_revenue
    FROM yearly_sales
)
SELECT
    sales_year,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_year_revenue, 2) AS previous_year_revenue,
    ROUND(100.0 * (revenue - previous_year_revenue) / NULLIF(previous_year_revenue, 0), 2) AS yoy_growth_pct
FROM growth
ORDER BY sales_year;

-- 11. Month-over-Month Revenue Growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
        SUM(oi.line_revenue) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
), monthly_growth AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (ORDER BY sales_month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(100.0 * (revenue - previous_month_revenue) / NULLIF(previous_month_revenue, 0), 2) AS mom_growth_pct
FROM monthly_growth
ORDER BY sales_month;

-- 12. Cumulative Revenue
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
           SUM(oi.line_revenue) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    sales_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY sales_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM monthly_sales
ORDER BY sales_month;

-- 13. 3-Month Moving Average
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
           SUM(oi.line_revenue) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    sales_month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (ORDER BY sales_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS revenue_3_month_moving_avg
FROM monthly_sales
ORDER BY sales_month;

-- 14. Best and Worst Sales Months
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
           SUM(oi.line_revenue) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
), ranked_months AS (
    SELECT
        sales_month,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS best_month_rank,
        RANK() OVER (ORDER BY revenue ASC) AS worst_month_rank
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    best_month_rank,
    worst_month_rank
FROM ranked_months
WHERE best_month_rank <= 5 OR worst_month_rank <= 5
ORDER BY revenue DESC;

-- 15. Revenue Share by Category
SELECT
    c.category_name,
    ROUND(SUM(oi.line_revenue), 2) AS category_revenue,
    ROUND(100.0 * SUM(oi.line_revenue) / SUM(SUM(oi.line_revenue)) OVER (), 2) AS revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.order_status = 'Completed'
GROUP BY c.category_name
ORDER BY category_revenue DESC;

-- 16. Cancelled Order Value
SELECT
    COUNT(DISTINCT o.order_id) AS cancelled_orders,
    ROUND(SUM(oi.line_revenue), 2) AS cancelled_order_value,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_cancelled_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Cancelled';

-- 17. Order Status Distribution
WITH order_totals AS (
    SELECT o.order_id, o.order_status, SUM(oi.line_revenue) AS order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_status
)
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(SUM(order_value), 2) AS order_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS order_share_pct
FROM order_totals
GROUP BY order_status
ORDER BY orders DESC;

-- 18. Sales by Day of Week
SELECT
    EXTRACT(ISODOW FROM o.order_date)::INT AS weekday_number,
    TO_CHAR(o.order_date, 'FMDay') AS weekday_name,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY EXTRACT(ISODOW FROM o.order_date), TO_CHAR(o.order_date, 'FMDay')
ORDER BY weekday_number;

-- 19. Top Country Within Each Market
WITH country_sales AS (
    SELECT r.market, r.country, SUM(oi.line_revenue) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN regions r ON o.region_id = r.region_id
    WHERE o.order_status = 'Completed'
    GROUP BY r.market, r.country
), ranked_countries AS (
    SELECT
        market,
        country,
        revenue,
        RANK() OVER (PARTITION BY market ORDER BY revenue DESC) AS revenue_rank
    FROM country_sales
)
SELECT
    market,
    country,
    ROUND(revenue, 2) AS revenue,
    revenue_rank
FROM ranked_countries
WHERE revenue_rank = 1
ORDER BY market;

-- 20. Reporting-Ready Monthly Sales Dataset
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    EXTRACT(YEAR FROM o.order_date)::INT AS sales_year,
    EXTRACT(MONTH FROM o.order_date)::INT AS month_number,
    TO_CHAR(o.order_date, 'Mon') AS month_name,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.line_revenue), 2) AS revenue,
    ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS cost,
    ROUND(SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost), 2) AS gross_profit,
    ROUND(100.0 * (SUM(oi.line_revenue) - SUM(oi.quantity * oi.unit_cost)) / NULLIF(SUM(oi.line_revenue), 0), 2) AS gross_margin_pct,
    ROUND(SUM(oi.line_revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY DATE_TRUNC('month', o.order_date), EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date), TO_CHAR(o.order_date, 'Mon')
ORDER BY sales_month;
