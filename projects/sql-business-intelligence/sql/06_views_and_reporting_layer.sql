-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- File: 06_views_and_reporting_layer.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL
-- Module: Reporting Layer / SQL Views
-- ============================================================

/*
PURPOSE
-------
This module creates reusable PostgreSQL views that expose
reporting-ready datasets for Business Intelligence tools such as Power BI.

The views consolidate logic created in the previous analysis modules:

01. Sales Analysis
02. Customer Analysis
03. Product Analysis
04. Operations Analysis
05. RFM Segmentation

BUSINESS VALUE
--------------
Instead of connecting BI tools directly to raw transactional tables,
the reporting layer provides clean, reusable analytical datasets.

BENEFITS
--------
- Centralised business logic
- Consistent KPI definitions
- Easier Power BI integration
- Reduced duplication
- Cleaner semantic model
- Better maintainability
- Faster report development

VIEWS CREATED
-------------
01. vw_executive_kpis
02. vw_sales_monthly
03. vw_customer_summary
04. vw_product_summary
05. vw_operations_monthly
06. vw_rfm_customers
07. vw_order_detail
08. vw_geographic_performance
*/


-- ============================================================
-- 01. EXECUTIVE KPI VIEW
-- ============================================================
-- Purpose:
-- Provides headline commercial and operational KPIs in one row.
-- ============================================================

CREATE OR REPLACE VIEW vw_executive_kpis AS

WITH sales_metrics AS (
    SELECT
        SUM(oi.line_revenue) AS total_revenue,

        SUM(
            oi.quantity * oi.unit_cost
        ) AS total_cost,

        SUM(oi.line_revenue)
        - SUM(
            oi.quantity * oi.unit_cost
        ) AS gross_profit,

        COUNT(
            DISTINCT o.order_id
        ) AS completed_orders,

        SUM(oi.quantity) AS units_sold

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'
),

order_metrics AS (
    SELECT
        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Pending'
        ) AS pending_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        ) AS cancelled_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
              AND delivered_date <= promised_date
        ) AS on_time_deliveries

    FROM orders
),

return_metrics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE return_status = 'Approved'
        ) AS approved_returns,

        COALESCE(
            SUM(refund_amount) FILTER (
                WHERE return_status = 'Approved'
            ),
            0
        ) AS refund_value

    FROM returns
)

SELECT
    ROUND(
        sm.total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        sm.total_cost,
        2
    ) AS total_cost,

    ROUND(
        sm.gross_profit,
        2
    ) AS gross_profit,

    ROUND(
        100.0 * sm.gross_profit
        / NULLIF(sm.total_revenue, 0),
        2
    ) AS gross_margin_pct,

    sm.completed_orders,

    sm.units_sold,

    ROUND(
        sm.total_revenue
        / NULLIF(sm.completed_orders, 0),
        2
    ) AS average_order_value,

    om.total_orders,

    om.pending_orders,

    om.cancelled_orders,

    ROUND(
        100.0 * om.cancelled_orders
        / NULLIF(om.total_orders, 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0 * om.on_time_deliveries
        / NULLIF(om.delivered_orders, 0),
        2
    ) AS on_time_delivery_rate_pct,

    rm.approved_returns,

    ROUND(
        rm.refund_value,
        2
    ) AS approved_refund_value

FROM sales_metrics sm

CROSS JOIN order_metrics om
CROSS JOIN return_metrics rm;


-- ============================================================
-- 02. MONTHLY SALES VIEW
-- ============================================================
-- Purpose:
-- Provides reporting-ready monthly sales and profitability metrics.
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_monthly AS

SELECT
    DATE_TRUNC(
        'month',
        o.order_date
    )::DATE AS sales_month,

    EXTRACT(
        YEAR FROM o.order_date
    )::INT AS sales_year,

    EXTRACT(
        MONTH FROM o.order_date
    )::INT AS month_number,

    TO_CHAR(
        o.order_date,
        'Mon'
    ) AS month_name,

    COUNT(
        DISTINCT o.order_id
    ) AS orders,

    SUM(
        oi.quantity
    ) AS units_sold,

    ROUND(
        SUM(oi.line_revenue),
        2
    ) AS revenue,

    ROUND(
        SUM(
            oi.quantity * oi.unit_cost
        ),
        2
    ) AS cost,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(
            oi.quantity * oi.unit_cost
        ),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(
                oi.quantity * oi.unit_cost
            )
        )
        / NULLIF(
            SUM(oi.line_revenue),
            0
        ),
        2
    ) AS gross_margin_pct,

    ROUND(
        SUM(oi.line_revenue)
        / NULLIF(
            COUNT(
                DISTINCT o.order_id
            ),
            0
        ),
        2
    ) AS average_order_value

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    DATE_TRUNC(
        'month',
        o.order_date
    ),
    EXTRACT(
        YEAR FROM o.order_date
    ),
    EXTRACT(
        MONTH FROM o.order_date
    ),
    TO_CHAR(
        o.order_date,
        'Mon'
    );


-- ============================================================
-- 03. CUSTOMER SUMMARY VIEW
-- ============================================================
-- Purpose:
-- Provides one analytical row per customer.
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_summary AS

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,

        r.country,
        r.market,

        MIN(o.order_date) FILTER (
            WHERE o.order_status = 'Completed'
        ) AS first_order_date,

        MAX(o.order_date) FILTER (
            WHERE o.order_status = 'Completed'
        ) AS last_order_date,

        COUNT(
            DISTINCT o.order_id
        ) FILTER (
            WHERE o.order_status = 'Completed'
        ) AS completed_orders,

        COALESCE(
            SUM(oi.quantity) FILTER (
                WHERE o.order_status = 'Completed'
            ),
            0
        ) AS units_purchased,

        COALESCE(
            SUM(oi.line_revenue) FILTER (
                WHERE o.order_status = 'Completed'
            ),
            0
        ) AS revenue,

        COALESCE(
            SUM(
                oi.quantity * oi.unit_cost
            ) FILTER (
                WHERE o.order_status = 'Completed'
            ),
            0
        ) AS cost

    FROM customers c

    LEFT JOIN regions r
        ON c.region_id = r.region_id

    LEFT JOIN orders o
        ON c.customer_id = o.customer_id

    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,
        r.market
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    market,

    first_order_date,
    last_order_date,

    completed_orders,
    units_purchased,

    ROUND(
        revenue,
        2
    ) AS lifetime_revenue,

    ROUND(
        cost,
        2
    ) AS lifetime_cost,

    ROUND(
        revenue - cost,
        2
    ) AS lifetime_gross_profit,

    ROUND(
        100.0 * (revenue - cost)
        / NULLIF(revenue, 0),
        2
    ) AS gross_margin_pct,

    ROUND(
        revenue
        / NULLIF(
            completed_orders,
            0
        ),
        2
    ) AS average_order_value,

    CASE
        WHEN completed_orders = 0
            THEN 'Never Purchased'

        WHEN completed_orders = 1
            THEN 'One-Time Customer'

        ELSE 'Repeat Customer'
    END AS purchase_status,

    CASE
        WHEN last_order_date IS NULL
            THEN NULL

        ELSE DATE '2025-12-31'
             - last_order_date
    END AS days_since_last_order,

    CASE
        WHEN last_order_date IS NULL
            THEN 'Never Purchased'

        WHEN DATE '2025-12-31'
             - last_order_date <= 90
            THEN 'Active'

        WHEN DATE '2025-12-31'
             - last_order_date <= 180
            THEN 'Watch'

        WHEN DATE '2025-12-31'
             - last_order_date <= 365
            THEN 'At Risk'

        ELSE 'Inactive'
    END AS activity_status

FROM customer_metrics;


-- ============================================================
-- 04. PRODUCT SUMMARY VIEW
-- ============================================================
-- Purpose:
-- Provides one analytical row per product.
-- ============================================================

CREATE OR REPLACE VIEW vw_product_summary AS

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.status,

        c.category_name,

        s.supplier_id,
        s.supplier_name,
        s.quality_score,

        COUNT(
            DISTINCT o.order_id
        ) AS completed_orders,

        COALESCE(
            SUM(oi.quantity),
            0
        ) AS units_sold,

        COALESCE(
            SUM(oi.line_revenue),
            0
        ) AS revenue,

        COALESCE(
            SUM(
                oi.quantity * oi.unit_cost
            ),
            0
        ) AS cost,

        AVG(
            oi.discount_pct
        ) AS avg_discount_pct,

        MIN(
            o.order_date
        ) AS first_sale_date,

        MAX(
            o.order_date
        ) AS last_sale_date

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

    WHERE o.order_id IS NOT NULL
       OR oi.order_id IS NULL

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

        COUNT(
            DISTINCT r.return_id
        ) FILTER (
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
    ps.units_sold,

    ROUND(
        ps.revenue,
        2
    ) AS revenue,

    ROUND(
        ps.cost,
        2
    ) AS cost,

    ROUND(
        ps.revenue - ps.cost,
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (ps.revenue - ps.cost)
        / NULLIF(
            ps.revenue,
            0
        ),
        2
    ) AS gross_margin_pct,

    ROUND(
        COALESCE(
            ps.avg_discount_pct,
            0
        ) * 100,
        2
    ) AS avg_discount_pct,

    COALESCE(
        pr.approved_returns,
        0
    ) AS approved_returns,

    ROUND(
        COALESCE(
            pr.refund_amount,
            0
        ),
        2
    ) AS refund_amount

FROM product_sales ps

LEFT JOIN product_returns pr
    ON ps.product_id = pr.product_id;


-- ============================================================
-- 05. MONTHLY OPERATIONS VIEW
-- ============================================================
-- Purpose:
-- Provides monthly order, delivery, payment and return KPIs.
-- ============================================================

CREATE OR REPLACE VIEW vw_operations_monthly AS

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_date
        )::DATE AS reporting_month,

        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
        ) AS completed_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Pending'
        ) AS pending_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        ) AS cancelled_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
              AND delivered_date <= promised_date
        ) AS on_time_orders,

        AVG(
            delivered_date - ship_date
        ) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
              AND ship_date IS NOT NULL
        ) AS avg_delivery_days

    FROM orders

    GROUP BY DATE_TRUNC(
        'month',
        order_date
    )
),

monthly_payments AS (
    SELECT
        DATE_TRUNC(
            'month',
            payment_date
        )::DATE AS reporting_month,

        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Paid'
            ),
            0
        ) AS paid_value,

        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Pending'
            ),
            0
        ) AS pending_payment_value,

        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Refunded'
            ),
            0
        ) AS refunded_payment_value

    FROM payments

    GROUP BY DATE_TRUNC(
        'month',
        payment_date
    )
),

monthly_returns AS (
    SELECT
        DATE_TRUNC(
            'month',
            return_date
        )::DATE AS reporting_month,

        COUNT(*) FILTER (
            WHERE return_status = 'Approved'
        ) AS approved_returns,

        COALESCE(
            SUM(refund_amount) FILTER (
                WHERE return_status = 'Approved'
            ),
            0
        ) AS approved_refund_value

    FROM returns

    GROUP BY DATE_TRUNC(
        'month',
        return_date
    )
)

SELECT
    mo.reporting_month,

    EXTRACT(
        YEAR FROM mo.reporting_month
    )::INT AS reporting_year,

    EXTRACT(
        MONTH FROM mo.reporting_month
    )::INT AS month_number,

    TO_CHAR(
        mo.reporting_month,
        'Mon'
    ) AS month_name,

    mo.total_orders,
    mo.completed_orders,
    mo.pending_orders,
    mo.cancelled_orders,

    ROUND(
        100.0 * mo.completed_orders
        / NULLIF(
            mo.total_orders,
            0
        ),
        2
    ) AS completion_rate_pct,

    ROUND(
        100.0 * mo.cancelled_orders
        / NULLIF(
            mo.total_orders,
            0
        ),
        2
    ) AS cancellation_rate_pct,

    mo.delivered_orders,

    ROUND(
        100.0 * mo.on_time_orders
        / NULLIF(
            mo.delivered_orders,
            0
        ),
        2
    ) AS on_time_delivery_rate_pct,

    ROUND(
        mo.avg_delivery_days,
        2
    ) AS average_delivery_days,

    ROUND(
        COALESCE(
            mp.paid_value,
            0
        ),
        2
    ) AS paid_value,

    ROUND(
        COALESCE(
            mp.pending_payment_value,
            0
        ),
        2
    ) AS pending_payment_value,

    ROUND(
        COALESCE(
            mp.refunded_payment_value,
            0
        ),
        2
    ) AS refunded_payment_value,

    COALESCE(
        mr.approved_returns,
        0
    ) AS approved_returns,

    ROUND(
        COALESCE(
            mr.approved_refund_value,
            0
        ),
        2
    ) AS approved_refund_value

FROM monthly_orders mo

LEFT JOIN monthly_payments mp
    ON mo.reporting_month
     = mp.reporting_month

LEFT JOIN monthly_returns mr
    ON mo.reporting_month
     = mr.reporting_month;


-- ============================================================
-- 06. RFM CUSTOMER VIEW
-- ============================================================
-- Purpose:
-- Exposes customer RFM scores and behavioural segments.
-- ============================================================

CREATE OR REPLACE VIEW vw_rfm_customers AS

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,

        r.country,
        r.market,

        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(
            DISTINCT o.order_id
        ) AS frequency,

        SUM(
            oi.quantity
        ) AS units_purchased,

        SUM(
            oi.line_revenue
        ) AS monetary_value,

        SUM(oi.line_revenue)
        - SUM(
            oi.quantity * oi.unit_cost
        ) AS gross_profit

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN regions r
        ON c.region_id = r.region_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,
        r.market
),

scores AS (
    SELECT
        *,

        6 - NTILE(5) OVER (
            ORDER BY recency_days ASC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS m_score

    FROM rfm_base
),

segmented AS (
    SELECT
        *,

        CASE
            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN r_score >= 3
             AND f_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN r_score = 5
             AND f_score = 1
                THEN 'New Customers'

            WHEN r_score >= 3
             AND f_score <= 2
                THEN 'Promising'

            WHEN r_score = 3
             AND f_score = 3
                THEN 'Needs Attention'

            WHEN r_score <= 2
             AND f_score >= 4
                THEN 'At Risk'

            WHEN r_score <= 2
             AND f_score BETWEEN 2 AND 3
                THEN 'Hibernating'

            WHEN r_score = 1
             AND f_score = 1
                THEN 'Lost'

            ELSE 'Other'
        END AS rfm_segment

    FROM scores
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    market,

    first_order_date,
    last_order_date,

    recency_days,
    frequency,
    units_purchased,

    ROUND(
        monetary_value,
        2
    ) AS lifetime_revenue,

    ROUND(
        gross_profit,
        2
    ) AS lifetime_gross_profit,

    ROUND(
        monetary_value
        / NULLIF(
            frequency,
            0
        ),
        2
    ) AS average_order_value,

    r_score,
    f_score,
    m_score,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score,

    r_score
        + f_score
        + m_score AS rfm_total_score,

    rfm_segment

FROM segmented;


-- ============================================================
-- 07. ORDER DETAIL VIEW
-- ============================================================
-- Purpose:
-- Provides transaction-level reporting grain for detailed BI analysis.
-- ============================================================

CREATE OR REPLACE VIEW vw_order_detail AS

SELECT
    o.order_id,
    oi.order_item_id,

    o.order_date,
    o.ship_date,
    o.promised_date,
    o.delivered_date,

    o.order_status,
    o.sales_channel,

    c.customer_id,

    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS customer_name,

    c.segment AS customer_segment,

    r.country,
    r.market,

    p.product_id,
    p.product_name,

    cat.category_name,

    s.supplier_id,
    s.supplier_name,

    sh.shipper_id,
    sh.shipper_name,

    oi.quantity,

    ROUND(
        oi.unit_price,
        2
    ) AS unit_price,

    ROUND(
        oi.unit_cost,
        2
    ) AS unit_cost,

    ROUND(
        oi.discount_pct * 100,
        2
    ) AS discount_pct,

    ROUND(
        oi.line_revenue,
        2
    ) AS line_revenue,

    ROUND(
        oi.quantity
        * oi.unit_cost,
        2
    ) AS line_cost,

    ROUND(
        oi.line_revenue
        - (
            oi.quantity
            * oi.unit_cost
        ),
        2
    ) AS line_gross_profit,

    CASE
        WHEN o.delivered_date IS NULL
            THEN NULL

        WHEN o.delivered_date
             <= o.promised_date
            THEN 'On Time'

        ELSE 'Late'
    END AS delivery_status,

    CASE
        WHEN o.delivered_date IS NULL
          OR o.promised_date IS NULL
            THEN NULL

        ELSE GREATEST(
            o.delivered_date
            - o.promised_date,
            0
        )
    END AS days_late

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN regions r
    ON o.region_id = r.region_id

JOIN products p
    ON oi.product_id = p.product_id

JOIN categories cat
    ON p.category_id = cat.category_id

JOIN suppliers s
    ON p.supplier_id = s.supplier_id

JOIN shippers sh
    ON o.shipper_id = sh.shipper_id;


-- ============================================================
-- 08. GEOGRAPHIC PERFORMANCE VIEW
-- ============================================================
-- Purpose:
-- Provides country and market-level commercial performance metrics.
-- ============================================================

CREATE OR REPLACE VIEW vw_geographic_performance AS

SELECT
    r.market,
    r.country,

    COUNT(
        DISTINCT c.customer_id
    ) AS customers,

    COUNT(
        DISTINCT o.order_id
    ) AS completed_orders,

    SUM(
        oi.quantity
    ) AS units_sold,

    ROUND(
        SUM(
            oi.line_revenue
        ),
        2
    ) AS revenue,

    ROUND(
        SUM(oi.line_revenue)
        - SUM(
            oi.quantity
            * oi.unit_cost
        ),
        2
    ) AS gross_profit,

    ROUND(
        100.0 *
        (
            SUM(oi.line_revenue)
            - SUM(
                oi.quantity
                * oi.unit_cost
            )
        )
        / NULLIF(
            SUM(
                oi.line_revenue
            ),
            0
        ),
        2
    ) AS gross_margin_pct,

    ROUND(
        SUM(
            oi.line_revenue
        )
        / NULLIF(
            COUNT(
                DISTINCT o.order_id
            ),
            0
        ),
        2
    ) AS average_order_value,

    ROUND(
        SUM(
            oi.line_revenue
        )
        / NULLIF(
            COUNT(
                DISTINCT c.customer_id
            ),
            0
        ),
        2
    ) AS revenue_per_customer

FROM regions r

JOIN orders o
    ON r.region_id = o.region_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    r.market,
    r.country;


-- ============================================================
-- VALIDATION QUERIES
-- ============================================================

-- List reporting views
SELECT
    table_name
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name LIKE 'vw_%'
ORDER BY table_name;


-- Executive KPIs
SELECT *
FROM vw_executive_kpis;


-- Monthly sales
SELECT *
FROM vw_sales_monthly
ORDER BY sales_month;


-- Top customers
SELECT *
FROM vw_customer_summary
ORDER BY lifetime_revenue DESC
LIMIT 20;


-- Top products
SELECT *
FROM vw_product_summary
ORDER BY revenue DESC
LIMIT 20;


-- Operations
SELECT *
FROM vw_operations_monthly
ORDER BY reporting_month;


-- RFM summary
SELECT
    rfm_segment,
    COUNT(*) AS customers,
    ROUND(
        SUM(lifetime_revenue),
        2
    ) AS revenue
FROM vw_rfm_customers
GROUP BY rfm_segment
ORDER BY revenue DESC;


-- Geographic performance
SELECT *
FROM vw_geographic_performance
ORDER BY revenue DESC;


