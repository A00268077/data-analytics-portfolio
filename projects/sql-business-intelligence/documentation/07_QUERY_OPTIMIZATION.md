# Query Optimization & Performance Analysis

## Overview

This module demonstrates a structured PostgreSQL query-optimization workflow using execution plans, planner statistics, indexing, and performance comparison.

The objective is not simply to create indexes.

The objective is to understand how PostgreSQL executes analytical queries, identify potential bottlenecks, apply appropriate optimization techniques, and validate whether those changes actually improve performance.

The primary SQL file is:

```text
sql/07_query_optimization.sql
```

---

## Optimization Workflow

The module follows a repeatable performance-engineering process:

1. Select an important analytical query.
2. Run `EXPLAIN ANALYZE`.
3. Inspect the execution plan.
4. Identify expensive scans, joins, sorts, or aggregations.
5. Create an appropriate index.
6. Run `ANALYZE` to refresh planner statistics.
7. Execute the query again.
8. Compare the before and after plans.
9. Keep the index only when it provides meaningful value.

This approach avoids creating unnecessary indexes without evidence.

---

## EXPLAIN vs EXPLAIN ANALYZE

### EXPLAIN

`EXPLAIN` displays the execution plan PostgreSQL expects to use.

It estimates:

- Query cost
- Rows processed
- Join strategies
- Scan strategies
- Sort operations

The query itself is not executed.

### EXPLAIN ANALYZE

`EXPLAIN ANALYZE` executes the query and reports actual runtime behaviour.

The project uses:

```sql
EXPLAIN (
    ANALYZE,
    BUFFERS
)
```

This provides both actual execution timing and buffer activity.

---

## Important Execution-Plan Concepts

### Sequential Scan

```text
Seq Scan
```

PostgreSQL reads the table sequentially.

This is not automatically a performance problem.

For small tables or queries returning a large percentage of rows, a sequential scan may be more efficient than using an index.

---

### Index Scan

```text
Index Scan
```

PostgreSQL uses an index to locate matching rows.

This is often useful when a query selects a relatively small subset of a larger table.

---

### Bitmap Index Scan

```text
Bitmap Index Scan
```

PostgreSQL first identifies matching locations using an index and then reads the required table pages.

This can be effective when more rows are required than would make a standard index scan efficient.

---

### Hash Join

```text
Hash Join
```

One input is loaded into a hash table and matched against another dataset.

Hash joins are commonly efficient for analytical joins involving larger result sets.

---

### Nested Loop

```text
Nested Loop
```

PostgreSQL repeatedly searches one input for rows matching another.

Nested loops can perform extremely well when one side is small and appropriate indexes exist.

---

## Performance Metrics

The module evaluates several plan-level indicators.

### Execution Time

```text
Execution Time
```

Actual query runtime.

This is one of the main before/after comparison metrics.

---

### Planning Time

```text
Planning Time
```

The time PostgreSQL spends selecting an execution strategy.

---

### Buffers

The `BUFFERS` option reports how PostgreSQL accesses data pages.

Important values can include:

- Shared hit
- Shared read
- Shared written

Lower physical reads can indicate more efficient data access.

---

## Existing Database Indexes

The original database schema already includes indexes for common transactional relationships, including:

- Order Date
- Order Customer ID
- Order Item Order ID
- Order Item Product ID
- Return Order Item ID

The optimization module adds selected analytical indexes rather than duplicating the existing schema.

---

## Analytical Indexes Added

### Completed Sales Date Index

```text
idx_orders_completed_date
```

Designed for completed-order time-series analysis.

The index is partial:

```text
WHERE order_status = 'Completed'
```

This means PostgreSQL stores index entries only for completed orders.

---

### Completed Customer History Index

```text
idx_orders_completed_customer_date
```

Supports repeated customer analytics involving:

- Customer ID
- Order Date
- Completed Orders

This access pattern appears frequently in customer lifetime value, retention, recency, and RFM analysis.

---

### Completed Region Index

```text
idx_orders_completed_region
```

Supports geographic BI queries where completed orders are aggregated by region.

---

### Payment Status and Date Index

```text
idx_payments_status_date
```

Supports operational reporting involving payment status and time.

---

### Approved Returns Index

```text
idx_returns_approved_reason
```

A partial index covering approved returns.

This reflects the analytical focus on realised return and refund activity.

---

### Product Category and Supplier Index

```text
idx_products_category_supplier
```

Supports product reporting that frequently joins products to categories and suppliers.

---

## Partial Indexes

Several indexes in the optimization module use a condition such as:

```sql
WHERE order_status = 'Completed'
```

This is known as a partial index.

Instead of indexing every row, PostgreSQL indexes only the subset relevant to frequent analytical queries.

Potential benefits include:

- Smaller indexes
- Less index storage
- Lower index maintenance cost
- Faster targeted lookups

Partial indexes are especially useful when BI queries repeatedly apply the same filter.

---

## Planner Statistics

After creating new indexes, the module runs:

```sql
ANALYZE table_name;
```

`ANALYZE` updates statistics used by the PostgreSQL query planner.

These statistics help PostgreSQL estimate:

- Row counts
- Data distribution
- Selectivity
- Join cardinality

An index may exist but still not be selected if planner statistics indicate that another plan is cheaper.

---

## Why an Index May Not Be Used

An important performance-engineering principle is:

> More indexes do not automatically mean faster queries.

PostgreSQL may continue using a sequential scan when:

- The table is small
- The query returns a large percentage of rows
- The index is not selective
- Data is already cached
- The cost of index lookups exceeds the cost of scanning the table

This behaviour is expected and demonstrates that the PostgreSQL optimizer is cost-based.

---

## Query Scenarios Tested

The module benchmarks several representative Business Intelligence workloads.

### Monthly Sales Analysis

Tests completed-order time-series aggregation.

### Customer Purchase History

Tests customer-level order and revenue aggregation.

### Geographic Sales Analysis

Tests regional aggregation across orders, regions, and order items.

### Payment Trend Analysis

Tests payment status and monthly reporting.

### Return Reason Analysis

Tests realised approved-return analysis.

### Product Category Analysis

Tests product/category sales aggregation.

### Reporting View Performance

The module also executes `EXPLAIN ANALYZE` against reporting views created in the previous module:

- `vw_sales_monthly`
- `vw_customer_summary`
- `vw_rfm_customers`

This demonstrates how view-based BI queries translate into underlying PostgreSQL execution plans.

---

## Index Usage Monitoring

PostgreSQL system statistics are used to inspect index activity.

The module queries:

```text
pg_stat_user_indexes
```

to review:

- Index scans
- Index tuples read
- Index tuples fetched

It also queries:

```text
pg_stat_user_tables
```

to compare sequential and index scan activity.

---

## Storage Analysis

Indexes improve read performance but consume disk space and introduce write-maintenance overhead.

The module therefore evaluates:

- Table size
- Index size
- Total relation size
- Database size

This reinforces the principle that indexing is a trade-off rather than a free optimization.

---

## SQL Techniques Demonstrated

This module demonstrates:

- `EXPLAIN`
- `EXPLAIN ANALYZE`
- `BUFFERS`
- Sequential-scan analysis
- Index-scan analysis
- Query-plan interpretation
- Composite indexes
- Partial indexes
- `CREATE INDEX IF NOT EXISTS`
- `ANALYZE`
- PostgreSQL statistics views
- Index-usage monitoring
- Table-size analysis
- Index-size analysis
- Before/after benchmarking
- BI-query optimization

---

## Query Structure

1. Current Index Inventory
2. Table Size Overview
3. Baseline Monthly Sales Query
4. Completed Sales Analytical Index
5. Optimized Monthly Sales Query
6. Baseline Customer Purchase History
7. Customer Analytics Index
8. Optimized Customer Purchase History
9. Baseline Geographic Analysis
10. Geographic Reporting Index
11. Optimized Geographic Analysis
12. Baseline Payment Trend
13. Payment Analytics Index
14. Optimized Payment Trend
15. Baseline Return Analysis
16. Approved Returns Partial Index
17. Optimized Return Analysis
18. Product Analytical Index
19. Product Category Performance Test
20. Sales View Performance Test
21. Customer View Performance Test
22. RFM View Performance Test
23. Index Usage Statistics
24. Sequential vs Index Scan Statistics
25. Final Index Inventory
26. Database Size
27. Table and Index Size Breakdown

---

## Business Value

Query optimization is important in Business Intelligence because dashboards can execute many analytical queries repeatedly.

As data volume grows, inefficient SQL can create:

- Slow dashboard refreshes
- Poor report responsiveness
- Increased server load
- Higher infrastructure cost
- Poor user experience

This module demonstrates that performance is treated as part of BI solution design rather than as an afterthought.

---

## Key Principle

The primary lesson of this module is:

> Measure first, optimize second.

Indexes and query rewrites should be supported by execution-plan evidence rather than added automatically.
