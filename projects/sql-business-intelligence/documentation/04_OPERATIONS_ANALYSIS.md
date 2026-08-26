# Operations Analysis Module

## Overview

This module analyses operational performance across order fulfilment, payments, returns, refunds, shipping, delivery performance, and cancellations using PostgreSQL.

The SQL file `04_operations_analysis.sql` combines financial and fulfilment data to provide management with a comprehensive view of operational efficiency and service quality.

The analysis covers the complete operational lifecycle from customer payment through fulfilment, delivery, return, refund, and cancellation.

---

## Business Objectives

This module answers the following questions:

- What is the overall order completion rate?
- What percentage of orders are cancelled?
- How much order value is lost through cancellations?
- How much payment value is collected, pending, or refunded?
- Which payment methods generate the most transaction value?
- Do payment issues vary by sales channel?
- What is the overall return rate?
- What are the primary reasons for product returns?
- Which return reasons create the greatest refund exposure?
- How are returns changing over time?
- Which shipping providers perform best?
- What is the average delivery time?
- What percentage of deliveries arrive on time?
- Which orders experience the longest delivery delays?
- Which geographic markets have weaker delivery performance?
- How are cancellations changing over time?
- Which sales channels experience the most operational issues?
- What operational dataset can be used in Power BI?

---

## Core Operational Metrics

The module evaluates operational performance using:

- Total Orders
- Completed Orders
- Pending Orders
- Cancelled Orders
- Completion Rate %
- Cancellation Rate %
- Paid Payment Value
- Pending Payment Value
- Refunded Payment Value
- Approved Returns
- Approved Return Rate %
- Approved Refund Value
- Average Refund
- Average Delivery Days
- On-Time Deliveries
- Late Deliveries
- On-Time Delivery Rate %
- Average Late Days
- Cancelled Order Value

---

## Payments Analysis

Payment activity is analysed by both status and payment method.

The analysis distinguishes between:

- Paid
- Pending
- Refunded

This provides visibility into successfully collected revenue as well as payment value that remains unresolved or has been reversed.

Payment methods are also compared to identify differences in transaction volume and value.

---

## Returns and Refunds

Return analysis focuses on approved returns because these represent realised operational and financial impact.

The module evaluates:

- Total Return Requests
- Approved Returns
- Rejected Returns
- Return Approval Rate
- Approved Refund Value
- Average Approved Refund
- Approved Return Rate

Return reasons are analysed separately to identify the operational causes creating the largest return volumes and refund exposure.

---

## Shipping and Delivery Performance

Shipping performance is evaluated using actual delivery dates and promised delivery dates.

An order is considered on time when:

```text
Delivered Date <= Promised Date
```

Delivery duration is calculated as:

```text
Delivered Date - Ship Date
```

The module compares shipping providers using:

- Completed Deliveries
- Average Delivery Days
- On-Time Deliveries
- Late Deliveries
- On-Time Delivery Rate
- Average Late Days

This helps identify logistics providers that consistently meet or miss service expectations.

---

## Geographic Delivery Performance

Delivery performance is also analysed by market and country.

This allows management to determine whether fulfilment problems are concentrated in specific geographic regions rather than being caused entirely by individual shipping providers.

---

## Cancellation Analysis

Cancelled orders represent unrealised sales opportunities.

The module calculates:

- Cancelled Order Count
- Cancellation Rate
- Cancelled Order Value
- Average Cancelled Order Value

Monthly cancellation trends make it possible to identify periods with unusually high cancellation activity.

---

## Sales Channel Operations

Sales channels are compared using:

- Total Orders
- Completed Orders
- Pending Orders
- Cancelled Orders
- Completion Rate
- Cancellation Rate
- On-Time Delivery Rate

This helps determine whether specific acquisition or ordering channels create greater operational complexity.

---

## SQL Techniques Demonstrated

This module demonstrates:

- Multi-table `JOIN`s
- `LEFT JOIN`
- `CROSS JOIN`
- CTEs
- Aggregate functions
- PostgreSQL `FILTER`
- `CASE`
- `COALESCE`
- `NULLIF`
- Date arithmetic
- `DATE_TRUNC()`
- Conditional aggregations
- Window percentages
- Operational KPI calculations
- Reporting-ready datasets

---

## Query Structure

1. Executive Operational KPI Summary
2. Payment Status Distribution
3. Payment Method Performance
4. Payment Status by Sales Channel
5. Monthly Payment Trend
6. Return KPI Summary
7. Approved Return Rate
8. Return Reasons Analysis
9. Refund Value by Return Reason
10. Monthly Return Trend
11. Shipping Performance by Shipper
12. Overall Delivery Performance
13. Late Delivery Analysis
14. Delivery Performance by Country
15. Cancellation KPI Summary
16. Monthly Cancellation Trend
17. Operational Performance by Sales Channel
18. Operational BI Monthly Summary Dataset

---

## Power BI Integration

Query 18 creates a reporting-ready monthly operational dataset containing:

- Reporting Month
- Reporting Year
- Month Number
- Month Name
- Total Orders
- Completed Orders
- Pending Orders
- Cancelled Orders
- Completion Rate %
- Cancellation Rate %
- Delivered Orders
- On-Time Delivery Rate %
- Average Delivery Days
- Paid Value
- Pending Payment Value
- Refunded Payment Value
- Approved Returns
- Approved Refund Value

This dataset can later be converted into a PostgreSQL view and connected directly to Power BI.

---

## Business Value

This module demonstrates how SQL can be used to analyse the operational side of Business Intelligence rather than focusing only on revenue.

By combining order fulfilment, payments, returns, logistics, delivery performance and cancellations, the analysis can support decisions related to:

- Payment operations
- Fulfilment efficiency
- Customer service
- Return reduction
- Logistics-provider management
- Delivery performance
- Cancellation reduction
- Operational risk
- Power BI reporting
