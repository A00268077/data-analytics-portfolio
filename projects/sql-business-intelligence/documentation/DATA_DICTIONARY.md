# Data Dictionary

## Grain
- `orders`: one row per customer order
- `order_items`: one row per product line within an order
- `returns`: one row per returned order item

## Core relationships
- customers 1 --- * orders
- employees 1 --- * orders
- shippers 1 --- * orders
- regions 1 --- * customers / employees / orders / suppliers
- orders 1 --- * order_items
- products 1 --- * order_items
- categories 1 --- * products
- suppliers 1 --- * products
- order_items 1 --- 0..1 returns

## Suggested business metrics
- Revenue: `SUM(order_items.line_revenue)`
- Cost: `SUM(order_items.quantity * order_items.unit_cost)`
- Gross profit: Revenue - Cost
- Gross margin %: Gross profit / Revenue
- Average order value: Revenue / distinct completed orders
- Return rate: returned items / sold items
- On-time delivery rate: delivered_date <= promised_date
- Customer lifetime value: total customer revenue

