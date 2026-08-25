-- Update the path before running in psql.
-- Example:
-- \set data_path '/absolute/path/to/sql_business_intelligence_dataset'

\copy regions FROM :'data_path'/regions.csv CSV HEADER;
\copy categories FROM :'data_path'/categories.csv CSV HEADER;
\copy shippers FROM :'data_path'/shippers.csv CSV HEADER;
\copy suppliers FROM :'data_path'/suppliers.csv CSV HEADER;
\copy products FROM :'data_path'/products.csv CSV HEADER;
\copy employees FROM :'data_path'/employees.csv CSV HEADER;
\copy customers FROM :'data_path'/customers.csv CSV HEADER;
\copy orders FROM :'data_path'/orders.csv CSV HEADER NULL '';
\copy order_items FROM :'data_path'/order_items.csv CSV HEADER;
\copy payments FROM :'data_path'/payments.csv CSV HEADER;
\copy returns FROM :'data_path'/returns.csv CSV HEADER;
