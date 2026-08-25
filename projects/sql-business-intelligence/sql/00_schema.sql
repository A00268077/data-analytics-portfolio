-- PostgreSQL schema for the SQL Business Intelligence Project

CREATE TABLE regions (
    region_id INT PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    market VARCHAR(50) NOT NULL,
    currency CHAR(3) NOT NULL
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE shippers (
    shipper_id INT PRIMARY KEY,
    shipper_name VARCHAR(100) NOT NULL,
    avg_delivery_days NUMERIC(5,2)
);

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    region_id INT REFERENCES regions(region_id),
    city VARCHAR(100),
    quality_score NUMERIC(5,3)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id INT REFERENCES categories(category_id),
    supplier_id INT REFERENCES suppliers(supplier_id),
    unit_cost NUMERIC(12,2) NOT NULL,
    list_price NUMERIC(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(80),
    last_name VARCHAR(80),
    email VARCHAR(150),
    department VARCHAR(80),
    job_title VARCHAR(80),
    region_id INT REFERENCES regions(region_id),
    hire_date DATE,
    annual_salary NUMERIC(12,2)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(80),
    last_name VARCHAR(80),
    email VARCHAR(150),
    segment VARCHAR(50),
    region_id INT REFERENCES regions(region_id),
    city VARCHAR(100),
    postal_code VARCHAR(30),
    signup_date DATE,
    status VARCHAR(30)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    employee_id INT REFERENCES employees(employee_id),
    shipper_id INT REFERENCES shippers(shipper_id),
    region_id INT REFERENCES regions(region_id),
    order_date DATE NOT NULL,
    ship_date DATE,
    promised_date DATE,
    delivered_date DATE,
    order_status VARCHAR(30),
    sales_channel VARCHAR(50)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    discount_pct NUMERIC(5,2) NOT NULL,
    unit_cost NUMERIC(12,2) NOT NULL,
    line_revenue NUMERIC(14,2) NOT NULL
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    payment_method VARCHAR(50),
    payment_status VARCHAR(30),
    amount NUMERIC(14,2),
    payment_date DATE
);

CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_item_id INT REFERENCES order_items(order_item_id),
    return_date DATE,
    return_reason VARCHAR(80),
    refund_amount NUMERIC(14,2),
    return_status VARCHAR(30)
);

CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_returns_order_item_id ON returns(order_item_id);
