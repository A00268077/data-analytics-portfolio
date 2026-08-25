# Sales Analysis Module

## Overview

This module analyses company sales performance using PostgreSQL.

The SQL file `01_sales_analysis.sql` contains 20 business-focused queries designed to evaluate revenue, profitability, growth, seasonality, geography, sales channels, product performance, and order status.

The analysis is based on completed orders unless otherwise specified.

---

## Business Objectives

The purpose of this module is to answer the following management questions:

- What is total revenue?
- What is total gross profit?
- What is the gross margin?
- How many completed orders were generated?
- What is the average order value?
- How are sales changing over time?
- Which markets and countries perform best?
- Which sales channels generate the most revenue?
- Which product categories generate the most revenue and profit?
- Which products are the highest-performing?
- How is revenue growing year over year?
- Are there strong seasonal sales patterns?
- How much potential revenue is lost through cancelled orders?
- What percentage of orders are completed, pending, or cancelled?
- Which days of the week generate the strongest sales?
- What reporting-ready dataset can be used in Power BI?

---

## Executive KPIs

The sales analysis produced the following headline results:

| KPI | Result |
|---|---:|
| Total Revenue | €13.01M |
| Total Cost | €8.74M |
| Gross Profit | €4.27M |
| Gross Margin | 32.83% |
| Completed Orders | 11,316 |
| Units Sold | 49,222 |
| Average Order Value | €1,149.58 |

---

## Key Business Insights

### Revenue Trend

Revenue remained almost flat in 2023, increased by 2.82% in 2024, and then declined by 4.51% in 2025.

This indicates that the business reached a revenue peak in 2024 before losing momentum in 2025.

### Seasonality

Sales show a strong recurring year-end pattern.

November and December consistently generate some of the highest monthly revenue values, while January and February are among the weakest months.

This suggests that inventory, staffing, and cash-flow planning should account for strong Q4 demand.

### Geographic Performance

Europe generates 77.15% of total revenue, making it the dominant market.

Ireland is the highest-performing country in Europe, while the United States leads North America.

This indicates a significant geographic concentration of company revenue.

### Sales Channels

Web and Mobile App channels generate nearly 73% of total revenue.

Web is the strongest channel by revenue and order volume.

Average order value remains relatively similar across all channels, suggesting that Web performance is driven mainly by higher order volume rather than larger baskets.

### Category Performance

Office is the largest revenue category and contributes 24.87% of total company revenue.

Sports & Outdoors generates the highest category gross margin at 35.31%.

This demonstrates that the highest-revenue category is not necessarily the most profitable in percentage terms.

### Product Performance

Office products dominate the Top 20 products by revenue.

However, the ranking by gross profit differs from the ranking by revenue, showing that strong sales volume does not always translate into the highest profitability.

Several lower-revenue products generate gross margins above 40%.

### Order Cancellations

891 cancelled orders represent approximately €1.04M in lost order value.

This highlights a meaningful opportunity to improve order completion and reduce lost revenue.

### Order Status

- Completed: 75.44%
- Pending: 18.62%
- Cancelled: 5.94%

The relatively high pending share suggests that order processing delays and ageing backlog should be investigated.

### Weekly Sales Pattern

Sales are relatively stable throughout the week.

Sunday records the highest average order value, suggesting that weekend customers tend to place higher-value orders.

---

## SQL Techniques Demonstrated

This module demonstrates the following PostgreSQL skills:

- INNER JOIN
- GROUP BY
- Aggregate functions
- CASE expressions
- Common Table Expressions (CTEs)
- Window functions
- LAG()
- RANK()
- PARTITION BY
- Running totals
- Moving averages
- Revenue share calculations
- Year-over-year growth
- Month-over-month growth
- Ranking analysis
- Reporting-ready datasets

---

## Query Structure

The file contains the following analytical sections:

1. Executive Sales KPI Summary
2. Annual Sales Performance
3. Monthly Sales Trend
4. Sales by Market
5. Sales by Country
6. Sales by Channel
7. Category Performance
8. Top Products by Revenue
9. Top Products by Gross Profit
10. Year-over-Year Revenue Growth
11. Month-over-Month Revenue Growth
12. Cumulative Revenue
13. 3-Month Moving Average
14. Best and Worst Sales Months
15. Revenue Share by Category
16. Cancelled Order Value
17. Order Status Distribution
18. Sales by Day of Week
19. Top Country within Each Market
20. Executive Monthly Sales Dataset

---

## Power BI Integration

The final query in `01_sales_analysis.sql` creates a reporting-ready monthly sales dataset containing:

- Sales Month
- Sales Year
- Month Number
- Month Name
- Orders
- Units Sold
- Revenue
- Cost
- Gross Profit
- Gross Margin %
- Average Order Value

This dataset is intended to be used later as a source for the Power BI executive dashboard.

---

## File Location

```text
projects/sql-business-intelligence/sql/01_sales_analysis.sql
```

## Related Documentation

```text
projects/sql-business-intelligence/documentation/01_SALES_ANALYSIS.md
```
