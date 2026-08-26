-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- File: 07_query_optimization.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL
-- Module: Query Optimization & Performance Analysis
-- ============================================================

/*
PURPOSE
-------
This module demonstrates how PostgreSQL query performance can be
evaluated and improved using:

- EXPLAIN
- EXPLAIN ANALYZE
- BUFFERS
- Composite indexes
- Partial indexes
- Statistics refresh
- Query-plan comparison

IMPORTANT
---------
Execution times depend on:
- Hardware
- PostgreSQL configuration
- Cache state
- Dataset size
- Existing indexes

The objective is not to prove that every index always improves every
query. The objective is to demonstrate a structured performance
optimization workflow.

OPTIMIZATION WORKFLOW
---------------------
1. Identify an important analytical query.
2. Run EXPLAIN ANALYZE.
3. Inspect scans, joins, costs and execution time.
4. Add an appropriate index.
5. Refresh statistics.
6. Run EXPLAIN ANALYZE again.
7. Compare the execution plans.
*/


-- ============================================================
-- 00. CURRENT INDEX INVENTORY
-- ============================================================
-- Business / technical value:
-- Documents the indexes already available in the database.

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- ============================================================
-- 01. TABLE SIZE OVERVIEW
-- ============================================================
-- Technical value:
-- Shows estimated row counts and table sizes before optimization.

SELECT
    relname AS table_name,

    n_live_tup AS estimated_rows,

    pg_size_pretty(
        pg_total_relation_size(relid)
    ) AS total_size

FROM pg_stat_user_tables

ORDER BY pg_total_relation_size(relid) DESC;


-- ============================================================
-- 02. BASELINE QUERY:
-- MONTHLY COMPLETED SALES
-- ============================================================
-- Goal:
-- Measure performance before adding an index focused on
-- completed-order time-series analysis.

EXPLAIN (
    ANALYZE,
    BUFFERS,
    VERBOSE,
    FORMAT TEXT
)
SELECT
    DATE_TRUNC(
        'month',
        o.order_date
    )::DATE AS sales_month,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY DATE_TRUNC(
    'month',
    o.order_date
)

ORDER BY sales_month;


-- ============================================================
-- 03. INDEX FOR COMPLETED SALES ANALYSIS
-- ============================================================
-- Rationale:
-- Sales reporting frequently filters on completed orders
-- and groups by order date.

CREATE INDEX IF NOT EXISTS
idx_orders_completed_date
ON orders (
    order_date,
    order_id
)
WHERE order_status = 'Completed';


-- Refresh planner statistics

ANALYZE orders;
ANALYZE order_items;


-- ============================================================
-- 04. AFTER INDEX:
-- MONTHLY COMPLETED SALES
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS,
    VERBOSE,
    FORMAT TEXT
)
SELECT
    DATE_TRUNC(
        'month',
        o.order_date
    )::DATE AS sales_month,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY DATE_TRUNC(
    'month',
    o.order_date
)

ORDER BY sales_month;


-- ============================================================
-- 05. BASELINE QUERY:
-- CUSTOMER PURCHASE HISTORY
-- ============================================================
-- Goal:
-- Evaluate a common customer-level analytical access pattern.

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    o.customer_id,

    COUNT(
        DISTINCT o.order_id
    ) AS completed_orders,

    MAX(
        o.order_date
    ) AS last_order_date,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS lifetime_revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY o.customer_id

ORDER BY lifetime_revenue DESC;


-- ============================================================
-- 06. INDEX FOR CUSTOMER ANALYTICS
-- ============================================================
-- Rationale:
-- Customer intelligence repeatedly filters completed orders
-- and accesses customer_id + order_date.

CREATE INDEX IF NOT EXISTS
idx_orders_completed_customer_date
ON orders (
    customer_id,
    order_date,
    order_id
)
WHERE order_status = 'Completed';


ANALYZE orders;


-- ============================================================
-- 07. AFTER INDEX:
-- CUSTOMER PURCHASE HISTORY
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    o.customer_id,

    COUNT(
        DISTINCT o.order_id
    ) AS completed_orders,

    MAX(
        o.order_date
    ) AS last_order_date,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS lifetime_revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY o.customer_id

ORDER BY lifetime_revenue DESC;


-- ============================================================
-- 08. BASELINE QUERY:
-- GEOGRAPHIC SALES PERFORMANCE
-- ============================================================
-- Goal:
-- Measure performance of a query filtering completed orders
-- and grouping by region.

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    r.market,
    r.country,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN regions r
    ON o.region_id = r.region_id

WHERE o.order_status = 'Completed'

GROUP BY
    r.market,
    r.country

ORDER BY revenue DESC;


-- ============================================================
-- 09. INDEX FOR GEOGRAPHIC REPORTING
-- ============================================================

CREATE INDEX IF NOT EXISTS
idx_orders_completed_region
ON orders (
    region_id,
    order_id
)
WHERE order_status = 'Completed';


ANALYZE orders;


-- ============================================================
-- 10. AFTER INDEX:
-- GEOGRAPHIC SALES PERFORMANCE
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    r.market,
    r.country,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN regions r
    ON o.region_id = r.region_id

WHERE o.order_status = 'Completed'

GROUP BY
    r.market,
    r.country

ORDER BY revenue DESC;


-- ============================================================
-- 11. BASELINE QUERY:
-- PAYMENT STATUS TREND
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    DATE_TRUNC(
        'month',
        payment_date
    )::DATE AS payment_month,

    payment_status,

    COUNT(*) AS payments,

    ROUND(
        SUM(amount),
        2
    ) AS payment_value

FROM payments

GROUP BY
    DATE_TRUNC(
        'month',
        payment_date
    ),
    payment_status

ORDER BY
    payment_month,
    payment_status;


-- ============================================================
-- 12. PAYMENT ANALYTICS INDEX
-- ============================================================

CREATE INDEX IF NOT EXISTS
idx_payments_status_date
ON payments (
    payment_status,
    payment_date
);


ANALYZE payments;


-- ============================================================
-- 13. AFTER INDEX:
-- PAYMENT STATUS TREND
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    DATE_TRUNC(
        'month',
        payment_date
    )::DATE AS payment_month,

    payment_status,

    COUNT(*) AS payments,

    ROUND(
        SUM(amount),
        2
    ) AS payment_value

FROM payments

GROUP BY
    DATE_TRUNC(
        'month',
        payment_date
    ),
    payment_status

ORDER BY
    payment_month,
    payment_status;


-- ============================================================
-- 14. BASELINE QUERY:
-- RETURN REASON ANALYSIS
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    return_reason,

    COUNT(*) AS approved_returns,

    ROUND(
        SUM(refund_amount),
        2
    ) AS refund_value

FROM returns

WHERE return_status = 'Approved'

GROUP BY return_reason

ORDER BY refund_value DESC;


-- ============================================================
-- 15. PARTIAL INDEX FOR APPROVED RETURNS
-- ============================================================
-- Rationale:
-- Business reporting primarily analyses realised / approved returns.

CREATE INDEX IF NOT EXISTS
idx_returns_approved_reason
ON returns (
    return_reason,
    return_date
)
WHERE return_status = 'Approved';


ANALYZE returns;


-- ============================================================
-- 16. AFTER INDEX:
-- RETURN REASON ANALYSIS
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    return_reason,

    COUNT(*) AS approved_returns,

    ROUND(
        SUM(refund_amount),
        2
    ) AS refund_value

FROM returns

WHERE return_status = 'Approved'

GROUP BY return_reason

ORDER BY refund_value DESC;


-- ============================================================
-- 17. PRODUCT / CATEGORY INDEX
-- ============================================================
-- Rationale:
-- Product reporting frequently joins category and supplier keys.

CREATE INDEX IF NOT EXISTS
idx_products_category_supplier
ON products (
    category_id,
    supplier_id,
    product_id
);


ANALYZE products;


-- ============================================================
-- 18. BASELINE / VALIDATION QUERY:
-- PRODUCT CATEGORY PERFORMANCE
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    c.category_name,

    COUNT(
        DISTINCT p.product_id
    ) AS products,

    SUM(
        oi.quantity
    ) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue

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
-- 19. VIEW PERFORMANCE TEST:
-- SALES MONTHLY
-- ============================================================
-- Goal:
-- Demonstrate EXPLAIN ANALYZE on the reporting layer.

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT *
FROM vw_sales_monthly
WHERE sales_year = 2025
ORDER BY sales_month;


-- ============================================================
-- 20. VIEW PERFORMANCE TEST:
-- CUSTOMER SUMMARY
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    lifetime_revenue,
    completed_orders

FROM vw_customer_summary

WHERE lifetime_revenue > 10000

ORDER BY lifetime_revenue DESC;


-- ============================================================
-- 21. VIEW PERFORMANCE TEST:
-- RFM CUSTOMER SEGMENTS
-- ============================================================

EXPLAIN (
    ANALYZE,
    BUFFERS
)
SELECT
    customer_id,
    rfm_segment,
    lifetime_revenue,
    rfm_total_score

FROM vw_rfm_customers

WHERE rfm_segment IN (
    'Champions',
    'At Risk'
)

ORDER BY lifetime_revenue DESC;


-- ============================================================
-- 22. INDEX USAGE STATISTICS
-- ============================================================
-- Technical value:
-- Shows whether PostgreSQL has used indexes and how frequently.

SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch

FROM pg_stat_user_indexes

ORDER BY
    idx_scan DESC,
    table_name,
    index_name;


-- ============================================================
-- 23. SEQUENTIAL VS INDEX SCAN STATISTICS
-- ============================================================

SELECT
    relname AS table_name,

    seq_scan,
    seq_tup_read,

    idx_scan,
    idx_tup_fetch

FROM pg_stat_user_tables

ORDER BY seq_tup_read DESC;


-- ============================================================
-- 24. FINAL INDEX INVENTORY
-- ============================================================

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef

FROM pg_indexes

WHERE schemaname = 'public'

ORDER BY
    tablename,
    indexname;


-- ============================================================
-- 25. DATABASE SIZE
-- ============================================================

SELECT
    pg_size_pretty(
        pg_database_size(
            current_database()
        )
    ) AS database_size;


-- ============================================================
-- 26. TABLE AND INDEX SIZE BREAKDOWN
-- ============================================================

SELECT
    relname AS table_name,

    pg_size_pretty(
        pg_relation_size(relid)
    ) AS table_size,

    pg_size_pretty(
        pg_indexes_size(relid)
    ) AS indexes_size,

    pg_size_pretty(
        pg_total_relation_size(relid)
    ) AS total_size

FROM pg_catalog.pg_statio_user_tables

ORDER BY
    pg_total_relation_size(relid) DESC;


-- ============================================================
-- OPTIONAL CLEANUP
-- ============================================================
-- DO NOT run this section if you want to keep the optimized indexes.
--
-- These statements are included only to make before/after
-- experiments repeatable.
--
-- DROP INDEX IF EXISTS idx_orders_completed_date;
-- DROP INDEX IF EXISTS idx_orders_completed_customer_date;
-- DROP INDEX IF EXISTS idx_orders_completed_region;
-- DROP INDEX IF EXISTS idx_payments_status_date;
-- DROP INDEX IF EXISTS idx_returns_approved_reason;
-- DROP INDEX IF EXISTS idx_products_category_supplier;


