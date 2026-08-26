-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- File: 04_operations_analysis.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL
-- Module: Operations Intelligence
-- ============================================================

/*
PURPOSE
-------
This module analyses operational performance across payments,
returns, refunds, order fulfilment, shipping, delivery performance
and cancellations.

BUSINESS QUESTIONS
------------------
01. What are the main operational KPIs?
02. How are payments distributed by status?
03. Which payment methods generate the most value?
04. How much payment value remains pending or refunded?
05. How does payment activity change over time?
06. What is the overall return and refund profile?
07. What is the approved return rate?
08. What are the main reasons for returns?
09. Which return reasons create the highest refund exposure?
10. How are returns changing over time?
11. Which shippers perform best?
12. What is the average delivery time?
13. What percentage of completed deliveries arrive late?
14. Which markets and countries have the strongest delivery performance?
15. What is the financial impact of cancelled orders?
16. How are cancellations changing over time?
17. Which sales channels experience the most operational issues?
18. What reporting-ready operational dataset can be used in Power BI?

NOTES
-----
Completed orders are treated as fulfilled sales.

On-time delivery:
    delivered_date <= promised_date

Delivery Days:
    delivered_date - ship_date

Late Days:
    delivered_date - promised_date

Approved returns are used for realised return/refund analysis.
*/


-- ============================================================
-- 01. EXECUTIVE OPERATIONAL KPI SUMMARY
-- ============================================================
-- Business value:
-- Provides a single executive view of completion, cancellation,
-- payment, returns and delivery performance.

WITH order_metrics AS (
    SELECT
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
        ) AS on_time_orders

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
        ) AS approved_refund_value

    FROM returns
),

payment_metrics AS (
    SELECT
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
)

SELECT
    om.total_orders,
    om.completed_orders,
    om.pending_orders,
    om.cancelled_orders,

    ROUND(
        100.0 * om.completed_orders
        / NULLIF(om.total_orders, 0),
        2
    ) AS completion_rate_pct,

    ROUND(
        100.0 * om.cancelled_orders
        / NULLIF(om.total_orders, 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0 * om.on_time_orders
        / NULLIF(om.delivered_orders, 0),
        2
    ) AS on_time_delivery_rate_pct,

    rm.approved_returns,

    ROUND(
        rm.approved_refund_value,
        2
    ) AS approved_refund_value,

    ROUND(pm.paid_value, 2) AS paid_value,
    ROUND(pm.pending_payment_value, 2) AS pending_payment_value,
    ROUND(pm.refunded_payment_value, 2) AS refunded_payment_value

FROM order_metrics om
CROSS JOIN return_metrics rm
CROSS JOIN payment_metrics pm;


-- ============================================================
-- 02. PAYMENT STATUS DISTRIBUTION
-- ============================================================
-- Business value:
-- Shows how much payment volume is successfully collected,
-- pending or refunded.

SELECT
    payment_status,

    COUNT(*) AS payments,

    ROUND(
        SUM(amount),
        2
    ) AS payment_value,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS payment_count_share_pct,

    ROUND(
        100.0 * SUM(amount)
        / SUM(SUM(amount)) OVER (),
        2
    ) AS payment_value_share_pct

FROM payments

GROUP BY payment_status
ORDER BY payment_value DESC;


-- ============================================================
-- 03. PAYMENT METHOD PERFORMANCE
-- ============================================================
-- Business value:
-- Compares payment methods by transaction volume, collected value,
-- pending value and refunds.

SELECT
    payment_method,

    COUNT(*) AS payments,

    ROUND(
        SUM(amount),
        2
    ) AS total_payment_value,

    ROUND(
        SUM(amount) FILTER (
            WHERE payment_status = 'Paid'
        ),
        2
    ) AS paid_value,

    ROUND(
        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Pending'
            ),
            0
        ),
        2
    ) AS pending_value,

    ROUND(
        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Refunded'
            ),
            0
        ),
        2
    ) AS refunded_value

FROM payments

GROUP BY payment_method
ORDER BY total_payment_value DESC;


-- ============================================================
-- 04. PAYMENT STATUS BY SALES CHANNEL
-- ============================================================
-- Business value:
-- Identifies channels with unusually high pending or refunded
-- payment exposure.

SELECT
    o.sales_channel,
    p.payment_status,

    COUNT(*) AS payments,

    ROUND(
        SUM(p.amount),
        2
    ) AS payment_value

FROM payments p

JOIN orders o
    ON p.order_id = o.order_id

GROUP BY
    o.sales_channel,
    p.payment_status

ORDER BY
    o.sales_channel,
    payment_value DESC;


-- ============================================================
-- 05. MONTHLY PAYMENT TREND
-- ============================================================
-- Business value:
-- Tracks payment collection, pending balances and refunds over time.

SELECT
    DATE_TRUNC(
        'month',
        payment_date
    )::DATE AS payment_month,

    ROUND(
        SUM(amount) FILTER (
            WHERE payment_status = 'Paid'
        ),
        2
    ) AS paid_value,

    ROUND(
        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Pending'
            ),
            0
        ),
        2
    ) AS pending_value,

    ROUND(
        COALESCE(
            SUM(amount) FILTER (
                WHERE payment_status = 'Refunded'
            ),
            0
        ),
        2
    ) AS refunded_value,

    COUNT(*) AS payments

FROM payments

GROUP BY DATE_TRUNC(
    'month',
    payment_date
)

ORDER BY payment_month;


-- ============================================================
-- 06. RETURN KPI SUMMARY
-- ============================================================
-- Business value:
-- Provides an executive view of return volume and financial exposure.

SELECT
    COUNT(*) AS total_return_requests,

    COUNT(*) FILTER (
        WHERE return_status = 'Approved'
    ) AS approved_returns,

    COUNT(*) FILTER (
        WHERE return_status = 'Rejected'
    ) AS rejected_returns,

    ROUND(
        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS approved_refund_value,

    ROUND(
        AVG(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS average_approved_refund,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE return_status = 'Approved'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS approval_rate_pct

FROM returns;


-- ============================================================
-- 07. APPROVED RETURN RATE
-- ============================================================
-- Business value:
-- Calculates the percentage of completed sold order lines
-- that resulted in an approved return.

WITH completed_lines AS (
    SELECT
        COUNT(oi.order_item_id) AS sold_order_lines

    FROM order_items oi

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'
),

approved_returns AS (
    SELECT
        COUNT(*) AS approved_return_lines

    FROM returns

    WHERE return_status = 'Approved'
)

SELECT
    cl.sold_order_lines,
    ar.approved_return_lines,

    ROUND(
        100.0 * ar.approved_return_lines
        / NULLIF(cl.sold_order_lines, 0),
        2
    ) AS approved_return_rate_pct

FROM completed_lines cl
CROSS JOIN approved_returns ar;


-- ============================================================
-- 08. RETURN REASONS ANALYSIS
-- ============================================================
-- Business value:
-- Identifies the operational drivers behind product returns.

SELECT
    return_reason,

    COUNT(*) AS return_requests,

    COUNT(*) FILTER (
        WHERE return_status = 'Approved'
    ) AS approved_returns,

    ROUND(
        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS refund_value,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS return_reason_share_pct

FROM returns

GROUP BY return_reason
ORDER BY return_requests DESC;


-- ============================================================
-- 09. REFUND VALUE BY RETURN REASON
-- ============================================================
-- Business value:
-- Identifies return reasons creating the largest financial cost.

SELECT
    return_reason,

    COUNT(*) FILTER (
        WHERE return_status = 'Approved'
    ) AS approved_returns,

    ROUND(
        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS refund_value,

    ROUND(
        AVG(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS average_refund,

    ROUND(
        100.0 *
        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        )
        /
        NULLIF(
            SUM(
                SUM(refund_amount) FILTER (
                    WHERE return_status = 'Approved'
                )
            ) OVER (),
            0
        ),
        2
    ) AS refund_value_share_pct

FROM returns

GROUP BY return_reason
ORDER BY refund_value DESC;


-- ============================================================
-- 10. MONTHLY RETURN TREND
-- ============================================================
-- Business value:
-- Tracks return activity and refund exposure over time.

SELECT
    DATE_TRUNC(
        'month',
        return_date
    )::DATE AS return_month,

    COUNT(*) AS return_requests,

    COUNT(*) FILTER (
        WHERE return_status = 'Approved'
    ) AS approved_returns,

    ROUND(
        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
        ),
        2
    ) AS refund_value

FROM returns

GROUP BY DATE_TRUNC(
    'month',
    return_date
)

ORDER BY return_month;


-- ============================================================
-- 11. SHIPPING PERFORMANCE BY SHIPPER
-- ============================================================
-- Business value:
-- Compares logistics providers on delivery speed and on-time
-- fulfilment performance.

SELECT
    s.shipper_id,
    s.shipper_name,
    s.avg_delivery_days AS contracted_avg_delivery_days,

    COUNT(*) AS completed_deliveries,

    ROUND(
        AVG(
            o.delivered_date - o.ship_date
        ),
        2
    ) AS actual_avg_delivery_days,

    COUNT(*) FILTER (
        WHERE o.delivered_date <= o.promised_date
    ) AS on_time_deliveries,

    COUNT(*) FILTER (
        WHERE o.delivered_date > o.promised_date
    ) AS late_deliveries,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE o.delivered_date <= o.promised_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate_pct,

    ROUND(
        AVG(
            GREATEST(
                o.delivered_date - o.promised_date,
                0
            )
        ),
        2
    ) AS avg_late_days

FROM shippers s

JOIN orders o
    ON s.shipper_id = o.shipper_id

WHERE o.order_status = 'Completed'
  AND o.ship_date IS NOT NULL
  AND o.delivered_date IS NOT NULL
  AND o.promised_date IS NOT NULL

GROUP BY
    s.shipper_id,
    s.shipper_name,
    s.avg_delivery_days

ORDER BY on_time_delivery_rate_pct DESC;


-- ============================================================
-- 12. OVERALL DELIVERY PERFORMANCE
-- ============================================================
-- Business value:
-- Provides executive delivery KPIs across all fulfilled orders.

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            delivered_date - ship_date
        ),
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(
            ship_date - order_date
        ),
        2
    ) AS average_processing_days,

    COUNT(*) FILTER (
        WHERE delivered_date <= promised_date
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivered_date > promised_date
    ) AS late_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE delivered_date <= promised_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate_pct

FROM orders

WHERE order_status = 'Completed'
  AND ship_date IS NOT NULL
  AND delivered_date IS NOT NULL
  AND promised_date IS NOT NULL;


-- ============================================================
-- 13. LATE DELIVERY ANALYSIS
-- ============================================================
-- Business value:
-- Quantifies delivery-delay severity and identifies the most
-- delayed orders.

SELECT
    o.order_id,
    r.country,
    o.sales_channel,
    s.shipper_name,
    o.order_date,
    o.promised_date,
    o.delivered_date,

    o.delivered_date
        - o.promised_date AS days_late

FROM orders o

JOIN regions r
    ON o.region_id = r.region_id

JOIN shippers s
    ON o.shipper_id = s.shipper_id

WHERE o.order_status = 'Completed'
  AND o.delivered_date IS NOT NULL
  AND o.promised_date IS NOT NULL
  AND o.delivered_date > o.promised_date

ORDER BY days_late DESC,
         o.order_id;


-- ============================================================
-- 14. DELIVERY PERFORMANCE BY COUNTRY
-- ============================================================
-- Business value:
-- Identifies geographic markets with stronger or weaker
-- fulfilment performance.

SELECT
    r.market,
    r.country,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            o.delivered_date - o.ship_date
        ),
        2
    ) AS average_delivery_days,

    COUNT(*) FILTER (
        WHERE o.delivered_date <= o.promised_date
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE o.delivered_date > o.promised_date
    ) AS late_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE o.delivered_date <= o.promised_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_rate_pct

FROM orders o

JOIN regions r
    ON o.region_id = r.region_id

WHERE o.order_status = 'Completed'
  AND o.ship_date IS NOT NULL
  AND o.delivered_date IS NOT NULL
  AND o.promised_date IS NOT NULL

GROUP BY
    r.market,
    r.country

ORDER BY on_time_delivery_rate_pct DESC;


-- ============================================================
-- 15. CANCELLATION KPI SUMMARY
-- ============================================================
-- Business value:
-- Measures cancellation volume, cancellation rate and estimated
-- lost order value.

WITH order_values AS (
    SELECT
        o.order_id,
        o.order_status,
        o.sales_channel,

        SUM(oi.line_revenue) AS order_value

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    GROUP BY
        o.order_id,
        o.order_status,
        o.sales_channel
)

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'Cancelled'
    ) AS cancelled_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        SUM(order_value) FILTER (
            WHERE order_status = 'Cancelled'
        ),
        2
    ) AS cancelled_order_value,

    ROUND(
        AVG(order_value) FILTER (
            WHERE order_status = 'Cancelled'
        ),
        2
    ) AS average_cancelled_order_value

FROM order_values;


-- ============================================================
-- 16. MONTHLY CANCELLATION TREND
-- ============================================================
-- Business value:
-- Tracks cancellation rates and financial exposure over time.

WITH order_values AS (
    SELECT
        o.order_id,
        o.order_date,
        o.order_status,

        SUM(oi.line_revenue) AS order_value

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    GROUP BY
        o.order_id,
        o.order_date,
        o.order_status
)

SELECT
    DATE_TRUNC(
        'month',
        order_date
    )::DATE AS order_month,

    COUNT(*) AS orders,

    COUNT(*) FILTER (
        WHERE order_status = 'Cancelled'
    ) AS cancelled_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        COALESCE(
            SUM(order_value) FILTER (
                WHERE order_status = 'Cancelled'
            ),
            0
        ),
        2
    ) AS cancelled_order_value

FROM order_values

GROUP BY DATE_TRUNC(
    'month',
    order_date
)

ORDER BY order_month;


-- ============================================================
-- 17. OPERATIONAL PERFORMANCE BY SALES CHANNEL
-- ============================================================
-- Business value:
-- Compares sales channels across completion, cancellation,
-- pending orders and delivery performance.

SELECT
    sales_channel,

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

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS completion_rate_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Completed'
              AND delivered_date IS NOT NULL
              AND delivered_date <= promised_date
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'Completed'
                  AND delivered_date IS NOT NULL
            ),
            0
        ),
        2
    ) AS on_time_delivery_rate_pct

FROM orders

GROUP BY sales_channel
ORDER BY total_orders DESC;


-- ============================================================
-- 18. OPERATIONAL BI MONTHLY SUMMARY DATASET
-- ============================================================
-- Business value:
-- Creates a reporting-ready monthly operational dataset suitable
-- for PostgreSQL VIEW creation and Power BI.

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

        SUM(amount) FILTER (
            WHERE payment_status = 'Paid'
        ) AS paid_value,

        SUM(amount) FILTER (
            WHERE payment_status = 'Pending'
        ) AS pending_payment_value,

        SUM(amount) FILTER (
            WHERE payment_status = 'Refunded'
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

        SUM(refund_amount) FILTER (
            WHERE return_status = 'Approved'
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
        / NULLIF(mo.total_orders, 0),
        2
    ) AS completion_rate_pct,

    ROUND(
        100.0 * mo.cancelled_orders
        / NULLIF(mo.total_orders, 0),
        2
    ) AS cancellation_rate_pct,

    mo.delivered_orders,

    ROUND(
        100.0 * mo.on_time_orders
        / NULLIF(mo.delivered_orders, 0),
        2
    ) AS on_time_delivery_rate_pct,

    ROUND(
        mo.avg_delivery_days,
        2
    ) AS average_delivery_days,

    ROUND(
        COALESCE(mp.paid_value, 0),
        2
    ) AS paid_value,

    ROUND(
        COALESCE(mp.pending_payment_value, 0),
        2
    ) AS pending_payment_value,

    ROUND(
        COALESCE(mp.refunded_payment_value, 0),
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
    ON mo.reporting_month = mp.reporting_month

LEFT JOIN monthly_returns mr
    ON mo.reporting_month = mr.reporting_month

ORDER BY mo.reporting_month;


