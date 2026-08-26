# SQL Views and Reporting Layer

## Overview

This module creates a reusable PostgreSQL reporting layer for the SQL Business Intelligence project.

Rather than requiring Business Intelligence tools to repeatedly reproduce complex joins, calculations, and segmentation logic, the reporting layer exposes clean analytical views that can be consumed directly by Power BI.

The module consolidates business logic developed across the previous analysis areas:

- Sales Analysis
- Customer Analysis
- Product Analysis
- Operations Analysis
- RFM Customer Segmentation

---

## Business Objective

The purpose of the reporting layer is to separate transactional database structure from analytical reporting requirements.

Raw operational tables are optimised for storing transactions, while Business Intelligence reports require datasets that are:

- Easier to understand
- Consistent
- Reusable
- Reporting-ready
- Business-oriented

PostgreSQL views provide this intermediate analytical layer.

---

## Reporting Architecture

The project follows a three-layer concept:

```text
Raw PostgreSQL Tables
        ↓
SQL Business Logic
        ↓
Reporting Views
        ↓
Power BI
```

The raw database contains normalised transactional tables such as:

- Orders
- Order Items
- Customers
- Products
- Payments
- Returns

The reporting views combine these tables and expose business-friendly metrics.

---

## Views Created

### vw_executive_kpis

Provides the primary executive KPIs in a single row.

Metrics include:

- Total Revenue
- Total Cost
- Gross Profit
- Gross Margin %
- Completed Orders
- Units Sold
- Average Order Value
- Total Orders
- Pending Orders
- Cancelled Orders
- Cancellation Rate %
- On-Time Delivery Rate %
- Approved Returns
- Approved Refund Value

This view can be used directly for executive KPI cards in Power BI.

---

### vw_sales_monthly

Provides monthly commercial performance.

Fields include:

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

This view supports:

- Revenue trends
- Profit trends
- Monthly KPI reporting
- Seasonal analysis
- Year-over-year comparisons

---

### vw_customer_summary

Provides one row per customer.

Metrics include:

- Customer Segment
- Country
- Market
- First Order Date
- Last Order Date
- Completed Orders
- Units Purchased
- Lifetime Revenue
- Lifetime Cost
- Lifetime Gross Profit
- Gross Margin %
- Average Order Value
- Purchase Status
- Days Since Last Order
- Activity Status

This view supports customer analytics and retention reporting.

---

### vw_product_summary

Provides one row per product.

Metrics include:

- Product
- Category
- Supplier
- Supplier Quality Score
- Product Status
- First Sale Date
- Last Sale Date
- Completed Orders
- Units Sold
- Revenue
- Cost
- Gross Profit
- Gross Margin %
- Average Discount %
- Approved Returns
- Refund Amount

This view supports product, category, supplier, profitability, and returns analysis.

---

### vw_operations_monthly

Provides monthly operational KPIs.

Metrics include:

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

This view supports operational dashboards and service-quality reporting.

---

### vw_rfm_customers

Provides customer-level RFM segmentation.

Fields include:

- Customer
- Segment
- Country
- Market
- First Order Date
- Last Order Date
- Recency
- Frequency
- Units Purchased
- Lifetime Revenue
- Lifetime Gross Profit
- Average Order Value
- R Score
- F Score
- M Score
- RFM Score
- RFM Total Score
- RFM Segment

This view supports customer segmentation and retention analytics.

---

### vw_order_detail

Provides transaction-level reporting data at order-item grain.

The view combines:

- Orders
- Customers
- Regions
- Products
- Categories
- Suppliers
- Shippers

Metrics and attributes include:

- Order Date
- Customer
- Product
- Category
- Market
- Country
- Sales Channel
- Shipper
- Quantity
- Unit Price
- Unit Cost
- Discount %
- Revenue
- Cost
- Gross Profit
- Delivery Status
- Days Late

This provides a flexible detail-level dataset for drill-through and exploratory Power BI analysis.

---

### vw_geographic_performance

Provides country and market-level commercial performance.

Metrics include:

- Customer Count
- Completed Orders
- Units Sold
- Revenue
- Gross Profit
- Gross Margin %
- Average Order Value
- Revenue per Customer

This view supports geographic performance reporting.

---

## Benefits of the Reporting Layer

### Consistent Business Logic

Metrics such as Revenue, Gross Profit, Average Order Value, and Customer Lifetime Revenue are calculated once in SQL rather than independently in every report.

### Easier Power BI Development

Power BI can connect to views containing already prepared analytical data rather than repeatedly joining transactional tables.

### Improved Maintainability

Business rules can be modified centrally within PostgreSQL.

Reports consuming the views automatically use the updated logic.

### Reduced Duplication

Repeated SQL logic from exploratory analysis can be converted into reusable database objects.

### Clear Separation of Responsibilities

The database handles:

- Data preparation
- Business logic
- Aggregation

Power BI handles:

- Visualisation
- Interaction
- Dashboard presentation

---

## SQL Techniques Demonstrated

This module demonstrates:

- `CREATE OR REPLACE VIEW`
- Multi-table joins
- CTEs
- Conditional aggregation
- PostgreSQL `FILTER`
- Window functions
- `NTILE()`
- `CASE`
- Date arithmetic
- `COALESCE`
- `NULLIF`
- Reporting-layer architecture
- Reusable business logic
- BI-oriented SQL design

---

## Power BI Integration

The reporting views are specifically designed for later Power BI integration.

Recommended Power BI sources:

### Executive Dashboard

```text
vw_executive_kpis
vw_sales_monthly
vw_geographic_performance
```

### Customer Dashboard

```text
vw_customer_summary
vw_rfm_customers
```

### Product Dashboard

```text
vw_product_summary
```

### Operations Dashboard

```text
vw_operations_monthly
```

### Drill-Through / Detail Analysis

```text
vw_order_detail
```

---

## Reporting Layer Structure

```text
PostgreSQL
│
├── Raw Tables
│   ├── customers
│   ├── orders
│   ├── order_items
│   ├── products
│   ├── categories
│   ├── suppliers
│   ├── employees
│   ├── regions
│   ├── shippers
│   ├── payments
│   └── returns
│
└── Reporting Views
    ├── vw_executive_kpis
    ├── vw_sales_monthly
    ├── vw_customer_summary
    ├── vw_product_summary
    ├── vw_operations_monthly
    ├── vw_rfm_customers
    ├── vw_order_detail
    └── vw_geographic_performance
```

---

## Business Value

The reporting layer transforms the PostgreSQL database from a transactional data source into a reusable Business Intelligence platform.

This architecture makes it possible to develop multiple Power BI dashboards using consistent business definitions without duplicating complex SQL logic.

It demonstrates an important BI engineering principle:

> Business logic should be reusable, consistent, and separated from presentation logic.
