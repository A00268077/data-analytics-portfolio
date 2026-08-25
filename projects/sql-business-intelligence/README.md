# SQL Business Intelligence Project

PostgreSQL-based Business Intelligence project analysing sales, profitability, customers, products and operational performance for a simulated multi-market retail company.

## Project Overview

This project demonstrates how SQL can be used to transform transactional data into business insights for executive decision-making.

The database contains more than 15,000 orders and 37,000 order line items across multiple countries, product categories and sales channels.

The analysis covers:

- Executive sales KPIs
- Revenue and profitability trends
- Year-over-year and month-over-month growth
- Market and country performance
- Sales channel performance
- Product and category analysis
- Customer analytics
- RFM segmentation
- Order cancellation analysis
- Returns and delivery performance
- Advanced SQL window functions
- Reporting datasets for Power BI

## Technology Stack

- PostgreSQL 18
- pgAdmin 4
- SQL
- Power BI
- GitHub

## Database

The relational database contains 11 tables:

- Customers
- Orders
- Order Items
- Products
- Categories
- Suppliers
- Employees
- Regions
- Shippers
- Payments
- Returns

## Dataset Size

| Entity | Records |
|---|---:|
| Customers | 3,000 |
| Products | 250 |
| Orders | 15,000 |
| Order Items | 37,892 |
| Returns | 2,079 |

## Key Sales KPIs

| KPI | Result |
|---|---:|
| Total Revenue | €13.01M |
| Gross Profit | €4.27M |
| Gross Margin | 32.83% |
| Completed Orders | 11,316 |
| Units Sold | 49,222 |
| Average Order Value | €1,149.58 |

## Key Business Insights

- Europe generates 77.15% of company revenue.
- Ireland and the United Kingdom are the strongest European markets.
- Web and Mobile App channels generate nearly 73% of revenue.
- Office is the largest category, contributing 24.87% of total revenue.
- Sports & Outdoors produces the strongest category gross margin at 35.31%.
- Sales show strong November–December seasonality.
- Revenue peaked in 2024 before declining 4.51% in 2025.
- 891 cancelled orders represent approximately €1.04M in lost order value.
- 18.62% of orders remain in Pending status.
- Weekend customers generate higher average order values.

## SQL Skills Demonstrated

- Multi-table JOINs
- GROUP BY and HAVING
- CASE expressions
- CTEs
- Window functions
- LAG
- RANK
- PARTITION BY
- Running totals
- Moving averages
- Revenue-share calculations
- Growth analysis
- Reporting-ready datasets

## Project Structure

```text
sql-business-intelligence/
├── data/
├── sql/
├── documentation/
├── screenshots/
├── powerbi/
├── BUSINESS_REQUIREMENTS.md
└── README.md

## Analysis Modules

### 01. Sales Analysis

The Sales Analysis module covers executive KPIs, revenue trends, profitability, seasonality, geographic performance, sales channels, product performance, cancellations, and advanced SQL window-function analysis.

- SQL: `sql/01_sales_analysis.sql`
- Documentation: `documentation/01_SALES_ANALYSIS.md`


