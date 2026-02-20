<img width="1680" height="706" alt="dashboard" src="https://github.com/user-attachments/assets/5f65009d-6489-4685-8283-216c443d0798" /># FNP Sales Analysis
<img width="305" height="165" alt="Image" src="https://github.com/user-attachments/assets/d09981ad-6ddb-4525-9644-54cb9d3813e1" />

# Project overview
This project analyses transactional retail datasets from FNP (Ferns and Petals) - an online platform specialising in gifts shipping with a variety of products - to understand customer purchasing behaviour, their preferences, product performance, revenue trends and shipping efficiency.
The project aims to perform end-to-end Excel dashboard projects and simulate practical business workflow: from transforming data, performing aggregration by SQL, delivering calculation and trend patterns in Excel and presenting a business performance via an interaction dashboard.

# Dataset description
Data source: https://github.com/Ayushi0214/FNP---Excel-Project/tree/main

The dataset includes details about customers, products, orders

| Table |Description |
|------------|-----------|
| orders | transactional purchase records | 
| products | product catalog with pricing | 
| customers | customers information | 

# Business questions
## Sales trends
- When do customers shop the most? (by months, quarter, days)
- How does sales fluctuates over the months in 2023?
- Evaluate revenue contribution of different occasions
- Present the number of orders and sales throughout weekdays 
## Products
- Identify top 5 products by revenue
- What products are most popular across different occasions?
- Which product category contributes most of the revenue?
- Sales and percent of revenue by category
- Identify product classification by their performance
## Customers
- Analyse customer behaviour based on genders
- How much do customers spend on average?
- Percentage of revenue that repeat customer contributes
- Perform customer segmentation and revenue for each segment
## Region
- Identify top 10 cities contributing the highest revenue
- Category spending by cities
- Delivery time rate by cities
## Operations
- Calculate average order-delivery time
- Identify total revenue of the company
- How many orders in total?
- Evaluate repeat purchase rate
- RFM Analysis
- Percent of late orders compared to total orders
# Tools and process
SQL was used to clean and transform raw transactional data into analytical metrics.
Excel was used for exploratory analysis and pivot-based validation.

| Tool |Purpose|
|------------|-------------------|
| Excel (Power Query, Power Pivot, Pivot Table)| clean and transform data by Power Query, manage relationships between tables with Power Pivot, sales calculation by Pivot table, build dashboard | 
| SQL (SELECT, JOIN, AGGREGRATION, CTE) | calculate key business metrics (RFM, Customer Segment, Product Classification,...) | 

# Dashboard
<img width="1680" height="706" alt="Image" src="https://github.com/user-attachments/assets/bc2f6929-2c45-45d4-b774-290acc108498" />

# SQL Aggregration
1. Average order value
```sql
SELECT ROUND(SUM(o.quantity*p.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders AS o
LEFT JOIN products AS p ON o.product_id = p.product_id;
```
|avg_order_value|
|3520.98|

2. Repeat purchase rate - customer purchasing more than or equal 10 times
```sql
WITH customer_orders AS (
	SELECT c.customer_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM customers AS c
    JOIN orders AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
customer_revenue AS (
	SELECT o.customer_id, SUM(o.quantity*p.price) AS total_spent
    FROM orders AS o
    JOIN products AS p ON p.product_id = o.product_id
    GROUP BY o.customer_id
)
SELECT ROUND(SUM(CASE WHEN order_count >= 10 THEN total_spent ELSE 0 END)/ SUM(total_spent)*100,2) AS repeat_customer_revenue_pct
FROM customer_orders AS co
JOIN customer_revenue AS cr ON co.customer_id = cr.customer_id;
```
|repeat_customer_revenue_pct|
|64.77|

3.
# Insights
The revenue of FNP relies on most of 3 main categories, including Sweets, Colors and Soft Toys.
