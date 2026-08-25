# SQL Business Intelligence Project

PostgreSQL-based Business Intelligence project analysing sales, profitability, customers, products, and operational performance for a simulated multi-market retail company.

## Project Overview

This project demonstrates how SQL can be used to transform transactional data into actionable business insights for executive decision-making.

The database contains 15,000 orders and more than 37,000 order line items across multiple countries, product categories, customer segments, and sales channels.

The project covers:

- Executive sales KPIs
- Revenue and profitability trends
- Year-over-year and month-over-month growth
- Market and country performance
- Sales channel performance
- Product and category analysis
- Customer value and retention analysis
- Customer segmentation
- Order cancellation analysis
- Returns and operational performance
- Advanced SQL window functions
- Reporting-ready datasets for Power BI

---

## Technology Stack

- PostgreSQL 18
- pgAdmin 4
- SQL
- Power BI
- GitHub

---

## Database

The relational PostgreSQL database contains 11 tables:

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

The database uses primary and foreign keys to model relationships between customers, transactions, products, employees, suppliers, geographic regions, payments, shipments, and returns.

---

## Dataset Size

| Entity | Records |
|---|---:|
| Customers | 3,000 |
| Products | 250 |
| Orders | 15,000 |
| Order Items | 37,892 |
| Returns | 2,079 |

The dataset covers the period from **2022 to 2025**.

---

## Key Sales KPIs

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

- Europe generates **77.15% of total company revenue**, making it the dominant geographic market.
- Ireland and the United Kingdom are the strongest European revenue contributors.
- Web and Mobile App channels generate nearly **73% of total revenue**.
- Office is the largest product category, contributing **24.87% of total revenue**.
- Sports & Outdoors generates the highest category gross margin at **35.31%**.
- Sales demonstrate strong year-end seasonality, with November and December consistently among the strongest months.
- Revenue peaked in 2024 before declining by **4.51% in 2025**.
- 891 cancelled orders represent approximately **€1.04M in lost order value**.
- **18.62% of orders remain Pending**, highlighting a potential opportunity to investigate order-processing delays.
- Sales are relatively stable across the week, while weekend customers tend to generate higher average order values.
- Product rankings by revenue and gross profit differ, demonstrating that high sales volume does not necessarily translate into the highest profitability.

---

## SQL Skills Demonstrated

The project demonstrates practical use of:

- Multi-table `JOIN`s
- `GROUP BY` and `HAVING`
- Aggregate functions
- `CASE` expressions
- Common Table Expressions (CTEs)
- Subqueries
- Window functions
- `LAG()`
- `ROW_NUMBER()`
- `RANK()`
- `NTILE()`
- `PARTITION BY`
- Running totals
- Moving averages
- Revenue-share calculations
- Year-over-year growth analysis
- Month-over-month growth analysis
- Customer concentration analysis
- Reporting-ready datasets

---

## Project Structure

```text
sql-business-intelligence/
│
├── data/
│   └── csv/
│
├── sql/
│   ├── 00_schema.sql
│   ├── 00_load_data_psql.sql
│   ├── 01_sales_analysis.sql
│   └── 02_customer_analysis.sql
│
├── documentation/
│   ├── DATA_DICTIONARY.md
│   └── 01_SALES_ANALYSIS.md
│
├── screenshots/
│   ├── README.md
│   ├── database-schema.png
│   ├── executive-kpis.png
│   └── advanced-sql-analysis.png
│
├── powerbi/
│   └── README.md
│
├── BUSINESS_REQUIREMENTS.md
└── README.md
```

---

## Analysis Modules

### 01. Sales Analysis

The Sales Analysis module evaluates executive KPIs, revenue trends, profitability, seasonality, geographic performance, sales channels, product performance, order cancellations, and advanced time-series analysis.

It contains **20 business-focused PostgreSQL queries**, including year-over-year growth, month-over-month growth, cumulative revenue, moving averages, ranking analysis, and a reporting-ready monthly dataset for Power BI.

**Files:**

- SQL: `sql/01_sales_analysis.sql`
- Documentation: `documentation/01_SALES_ANALYSIS.md`

### 02. Customer Analysis

The Customer Analysis module focuses on customer value, purchasing behaviour, retention, revenue concentration, and customer profitability.

The analysis includes:

- Customer Lifetime Value
- Top customers by revenue
- Repeat customer analysis
- Repeat customer rate
- Customer revenue concentration
- Pareto 80/20 analysis
- Customer segment performance
- Geographic customer performance
- Purchase frequency
- Inactive customer identification
- Customer recency and churn-risk proxy
- Average order value analysis
- New vs repeat customer revenue
- Customer gross profitability
- Customer value tiers
- Reporting-ready customer datasets

**Files:**

- SQL: `sql/02_customer_analysis.sql`
- Documentation: `documentation/02_CUSTOMER_ANALYSIS.md`

### 03. Product Analysis

The Product Analysis module evaluates product and category performance using revenue, gross profit, margins, sales volume, returns, supplier contribution, discount impact, revenue concentration, and product value segmentation.

The analysis combines commercial and operational KPIs to identify high-value products, underperforming SKUs, supplier exposure, return risk, and product portfolio opportunities.

- SQL: `sql/03_product_analysis.sql`
- Documentation: `documentation/03_PRODUCT_ANALYSIS.md`

---

## Power BI Integration

The SQL analysis is designed to support a later Power BI reporting layer.

Reporting-ready SQL datasets are being developed to support:

- Executive KPIs
- Revenue trends
- Profitability analysis
- Customer analytics
- Product performance
- Geographic performance
- Operational KPIs

---

## Project Status

**Completed**

- PostgreSQL database design
- Database schema and relationships
- Data loading process
- Sales analysis module
- Sales business insights
- Advanced sales window-function analysis

**In Progress**

- Customer intelligence analysis

**Planned**

- Product and profitability analysis
- RFM customer segmentation
- Returns and operational analysis
- SQL views
- Query optimisation and indexing
- Power BI executive dashboard

---

## Business Value

This project demonstrates an end-to-end Business Intelligence workflow: from relational database design and data loading to SQL analysis, business insight generation, and preparation of reporting-ready datasets.

Rather than focusing only on SQL syntax, the project is structured around realistic business questions and management decision-making.
