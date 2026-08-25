-- ============================================================
-- SQL BUSINESS INTELLIGENCE PROJECT
-- PostgreSQL data loading script
-- ============================================================
--
-- Before running:
-- 1. Open psql
-- 2. Connect to the database:
--      \c sql_business_intelligence
--
-- 3. Replace DATA_PATH below with your local project path.
--
-- Example:
-- C:/Projects/data-analytics-portfolio/projects/
-- sql-business-intelligence/data/raw/
-- ============================================================

\copy regions
FROM 'DATA_PATH/regions.csv'
CSV HEADER;

\copy categories
FROM 'DATA_PATH/categories.csv'
CSV HEADER;

\copy shippers
FROM 'DATA_PATH/shippers.csv'
CSV HEADER;

\copy suppliers
FROM 'DATA_PATH/suppliers.csv'
CSV HEADER;

\copy products
FROM 'DATA_PATH/products.csv'
CSV HEADER;

\copy employees
FROM 'DATA_PATH/employees.csv'
CSV HEADER;

\copy customers
FROM 'DATA_PATH/customers.csv'
CSV HEADER;

\copy orders
FROM 'DATA_PATH/orders.csv'
CSV HEADER;

\copy order_items
FROM 'DATA_PATH/order_items.csv'
CSV HEADER;

\copy payments
FROM 'DATA_PATH/payments.csv'
CSV HEADER;

\copy returns
FROM 'DATA_PATH/returns.csv'
CSV HEADER;
