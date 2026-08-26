-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- File: 05_rfm_segmentation.sql
-- Database: sql_business_intelligence
-- Platform: PostgreSQL
-- Module: RFM Customer Segmentation
-- ============================================================

/*
PURPOSE
-------
This module performs RFM segmentation using customer recency,
purchase frequency and monetary value.

RFM DIMENSIONS
--------------
Recency   = Days since the customer's most recent completed order
Frequency = Number of completed orders
Monetary  = Total completed-order revenue

REFERENCE DATE
--------------
2025-12-31

BUSINESS QUESTIONS
------------------
01. What are the core RFM metrics for each customer?
02. How should customers be scored on Recency?
03. How should customers be scored on Frequency?
04. How should customers be scored on Monetary value?
05. What is each customer's combined RFM score?
06. Which customers are Champions?
07. Which customers are Loyal Customers?
08. Which customers are Potential Loyalists?
09. Which customers are At Risk?
10. Which customers are Lost?
11. How large is each RFM segment?
12. How much revenue does each RFM segment generate?
13. What is average order value by RFM segment?
14. Which countries contain the strongest RFM segments?
15. Which customer segments contain the strongest RFM segments?
16. How can high-value churn-risk customers be identified?
17. How can RFM segments be prioritised commercially?
18. What reporting-ready RFM dataset can be used in Power BI?
*/


-- ============================================================
-- 01. CUSTOMER RFM BASE METRICS
-- ============================================================
-- Business value:
-- Creates the fundamental customer-level Recency, Frequency
-- and Monetary metrics used throughout the RFM model.

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,
        r.market,

        MAX(o.order_date) AS last_order_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

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
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    market,
    last_order_date,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value
FROM rfm_base
ORDER BY monetary_value DESC;


-- ============================================================
-- 02. RECENCY SCORE
-- ============================================================
-- Business value:
-- Scores customers from 1 to 5 based on how recently they purchased.
-- More recent customers receive higher scores.

WITH rfm_base AS (
    SELECT
        c.customer_id,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
)

SELECT
    customer_id,
    recency_days,

    6 - NTILE(5) OVER (
        ORDER BY recency_days ASC
    ) AS recency_score

FROM rfm_base
ORDER BY recency_score DESC,
         recency_days ASC;


-- ============================================================
-- 03. FREQUENCY SCORE
-- ============================================================
-- Business value:
-- Scores customers from 1 to 5 based on completed-order frequency.
-- Customers with more completed orders receive higher scores.

WITH frequency_base AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS frequency

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
)

SELECT
    customer_id,
    frequency,

    NTILE(5) OVER (
        ORDER BY frequency ASC
    ) AS frequency_score

FROM frequency_base
ORDER BY frequency_score DESC,
         frequency DESC;


-- ============================================================
-- 04. MONETARY SCORE
-- ============================================================
-- Business value:
-- Scores customers from 1 to 5 according to total realised revenue.

WITH monetary_base AS (
    SELECT
        c.customer_id,
        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
)

SELECT
    customer_id,
    ROUND(monetary_value, 2) AS monetary_value,

    NTILE(5) OVER (
        ORDER BY monetary_value ASC
    ) AS monetary_score

FROM monetary_base
ORDER BY monetary_score DESC,
         monetary_value DESC;


-- ============================================================
-- 05. COMPLETE RFM SCORING
-- ============================================================
-- Business value:
-- Combines customer Recency, Frequency and Monetary scores
-- into one reusable analytical dataset.

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,
        r.market,

        MAX(o.order_date) AS last_order_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

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

rfm_scores AS (
    SELECT
        *,

        6 - NTILE(5) OVER (
            ORDER BY recency_days ASC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score

    FROM rfm_base
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    market,
    last_order_date,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value,

    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_score,

    recency_score
        + frequency_score
        + monetary_score AS rfm_total_score

FROM rfm_scores

ORDER BY rfm_total_score DESC,
         monetary_value DESC;


-- ============================================================
-- 06. RFM CUSTOMER SEGMENTS
-- ============================================================
-- Business value:
-- Converts numerical RFM scores into business-friendly
-- customer segments suitable for retention and marketing action.

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,
        r.market,

        MAX(o.order_date) AS last_order_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

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

rfm_scores AS (
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

    FROM rfm_scores
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    market,
    last_order_date,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value,

    r_score,
    f_score,
    m_score,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score,

    rfm_segment

FROM segmented

ORDER BY
    CASE rfm_segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal Customers' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'New Customers' THEN 4
        WHEN 'Promising' THEN 5
        WHEN 'Needs Attention' THEN 6
        WHEN 'At Risk' THEN 7
        WHEN 'Hibernating' THEN 8
        WHEN 'Lost' THEN 9
        ELSE 10
    END,
    monetary_value DESC;


-- ============================================================
-- 07. RFM SEGMENT SIZE
-- ============================================================
-- Business value:
-- Shows how the customer population is distributed
-- across behavioural segments.

WITH rfm_base AS (
    SELECT
        c.customer_id,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
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

segments AS (
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
    rfm_segment,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_pct

FROM segments

GROUP BY rfm_segment
ORDER BY customers DESC;


-- ============================================================
-- 08. RFM SEGMENT REVENUE
-- ============================================================
-- Business value:
-- Measures the financial contribution of each behavioural segment.

WITH rfm_base AS (
    SELECT
        c.customer_id,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
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

segments AS (
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
    rfm_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS revenue,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value,

    ROUND(
        100.0 * SUM(monetary_value)
        / SUM(SUM(monetary_value)) OVER (),
        2
    ) AS revenue_share_pct

FROM segments

GROUP BY rfm_segment

ORDER BY revenue DESC;


-- ============================================================
-- 09. AVERAGE ORDER VALUE BY RFM SEGMENT
-- ============================================================
-- Business value:
-- Compares transaction value across behavioural customer groups.

WITH customer_metrics AS (
    SELECT
        c.customer_id,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
),

scored AS (
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

    FROM customer_metrics
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

    FROM scored
)

SELECT
    rfm_segment,

    ROUND(
        SUM(monetary_value)
        / NULLIF(SUM(frequency), 0),
        2
    ) AS average_order_value,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_orders_per_customer

FROM segmented

GROUP BY rfm_segment

ORDER BY average_order_value DESC;


-- ============================================================
-- 10. RFM SEGMENTS BY COUNTRY
-- ============================================================
-- Business value:
-- Identifies where high-value customer segments are concentrated.

WITH rfm_base AS (
    SELECT
        c.customer_id,
        r.country,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN regions r
        ON c.region_id = r.region_id

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        r.country
),

scored AS (
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

            WHEN r_score <= 2
             AND f_score >= 4
                THEN 'At Risk'

            WHEN r_score = 1
             AND f_score = 1
                THEN 'Lost'

            ELSE 'Other'
        END AS rfm_segment

    FROM scored
)

SELECT
    country,
    rfm_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS revenue

FROM segmented

GROUP BY
    country,
    rfm_segment

ORDER BY
    country,
    revenue DESC;


-- ============================================================
-- 11. RFM SEGMENTS BY CUSTOMER TYPE
-- ============================================================
-- Business value:
-- Compares RFM behaviour across Consumer, Small Business
-- and Corporate customer segments.

WITH rfm_base AS (
    SELECT
        c.customer_id,
        c.segment,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.segment
),

scored AS (
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

            WHEN r_score <= 2
             AND f_score >= 4
                THEN 'At Risk'

            WHEN r_score = 1
             AND f_score = 1
                THEN 'Lost'

            ELSE 'Other'
        END AS rfm_segment

    FROM scored
)

SELECT
    segment,
    rfm_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS revenue

FROM segmented

GROUP BY
    segment,
    rfm_segment

ORDER BY
    segment,
    revenue DESC;


-- ============================================================
-- 12. HIGH-VALUE CUSTOMERS AT RISK
-- ============================================================
-- Business value:
-- Identifies historically valuable customers whose purchasing
-- activity has become stale and may require retention action.

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,

        MAX(o.order_date) AS last_order_date,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN regions r
        ON c.region_id = r.region_id

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country
),

scored AS (
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

    FROM customer_metrics
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    last_order_date,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value,

    r_score,
    f_score,
    m_score

FROM scored

WHERE r_score <= 2
  AND (
        f_score >= 4
        OR m_score >= 4
      )

ORDER BY monetary_value DESC;


-- ============================================================
-- 13. CHAMPIONS
-- ============================================================
-- Business value:
-- Creates a focused list of the strongest customer relationships.

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN regions r
        ON c.region_id = r.region_id

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.segment,
        r.country
),

scored AS (
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

    FROM customer_metrics
)

SELECT
    customer_id,
    first_name,
    last_name,
    segment,
    country,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score

FROM scored

WHERE r_score >= 4
  AND f_score >= 4
  AND m_score >= 4

ORDER BY monetary_value DESC;


-- ============================================================
-- 14. LOST CUSTOMERS
-- ============================================================
-- Business value:
-- Identifies customers with the weakest recency and frequency,
-- providing a list for possible reactivation analysis.

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
),

scored AS (
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

    FROM customer_metrics
)

SELECT
    customer_id,
    first_name,
    last_name,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS historical_revenue,

    CONCAT(
        r_score,
        f_score,
        m_score
    ) AS rfm_score

FROM scored

WHERE r_score = 1
  AND f_score = 1

ORDER BY historical_revenue DESC;


-- ============================================================
-- 15. RFM ACTION FRAMEWORK
-- ============================================================
-- Business value:
-- Converts analytical RFM segments into actionable
-- commercial recommendations.

WITH segment_actions AS (
    SELECT *
    FROM (
        VALUES
            (
                'Champions',
                'Protect and reward',
                'VIP treatment, early access, loyalty rewards'
            ),
            (
                'Loyal Customers',
                'Retain and grow',
                'Cross-sell, upsell and loyalty offers'
            ),
            (
                'Potential Loyalists',
                'Develop relationship',
                'Second-purchase incentives and personalised offers'
            ),
            (
                'New Customers',
                'Build engagement',
                'Onboarding and early repeat-purchase incentives'
            ),
            (
                'Promising',
                'Increase frequency',
                'Targeted product recommendations'
            ),
            (
                'Needs Attention',
                'Re-engage',
                'Personalised reminder or incentive'
            ),
            (
                'At Risk',
                'Prevent churn',
                'Retention campaign and high-value outreach'
            ),
            (
                'Hibernating',
                'Reactivate selectively',
                'Win-back offers based on previous purchases'
            ),
            (
                'Lost',
                'Low-priority reactivation',
                'Low-cost automated win-back campaign'
            )
    ) AS t(
        rfm_segment,
        business_priority,
        recommended_action
    )
)

SELECT *
FROM segment_actions;


-- ============================================================
-- 16. RFM SEGMENT PRIORITY SCORE
-- ============================================================
-- Business value:
-- Creates a simple management ranking for customer segments.

SELECT *
FROM (
    VALUES
        (
            1,
            'Champions',
            'Very High'
        ),
        (
            2,
            'At Risk',
            'Very High'
        ),
        (
            3,
            'Loyal Customers',
            'High'
        ),
        (
            4,
            'Potential Loyalists',
            'High'
        ),
        (
            5,
            'Needs Attention',
            'Medium'
        ),
        (
            6,
            'New Customers',
            'Medium'
        ),
        (
            7,
            'Promising',
            'Medium'
        ),
        (
            8,
            'Hibernating',
            'Low'
        ),
        (
            9,
            'Lost',
            'Low'
        )
) AS priorities(
    priority_rank,
    rfm_segment,
    priority_level
)

ORDER BY priority_rank;


-- ============================================================
-- 17. RFM EXECUTIVE SUMMARY
-- ============================================================
-- Business value:
-- Provides a concise RFM-level summary for executive reporting.

WITH rfm_base AS (
    SELECT
        c.customer_id,

        DATE '2025-12-31'
            - MAX(o.order_date) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.line_revenue) AS monetary_value

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY c.customer_id
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

segments AS (
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
    rfm_segment,

    COUNT(*) AS customers,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency),
        2
    ) AS avg_order_frequency,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value,

    ROUND(
        SUM(monetary_value),
        2
    ) AS segment_revenue,

    ROUND(
        100.0 *
        SUM(monetary_value)
        / SUM(SUM(monetary_value)) OVER (),
        2
    ) AS revenue_share_pct

FROM segments

GROUP BY rfm_segment

ORDER BY segment_revenue DESC;


-- ============================================================
-- 18. RFM BI SUMMARY DATASET
-- ============================================================
-- Business value:
-- Creates a customer-level reporting dataset suitable for
-- PostgreSQL VIEW creation and Power BI.

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

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(oi.quantity) AS units_purchased,

        SUM(oi.line_revenue) AS monetary_value,

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

final_rfm AS (
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
        / NULLIF(frequency, 0),
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

FROM final_rfm

ORDER BY
    rfm_total_score DESC,
    lifetime_revenue DESC;

