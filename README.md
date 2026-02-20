# FNP SALES ANALYSIS
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
<img width="1680" height="706" alt="dashboard" src="https://github.com/user-attachments/assets/5f65009d-6489-4685-8283-216c443d0798" /># FNP Sales Analysis

# SQL key metrics
1. Repeat purchase rate - customer purchasing more than or equal 10 times
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
|------------|
| 64.77 | 

2. Customer segmentation and percentage of revenue for each segment
```sql
WITH customer_revenue AS (
	SELECT o.customer_id, SUM(o.quantity*p.price) AS revenue
    FROM orders AS o 
    JOIN products AS p ON o.product_id = p.product_id
    GROUP BY o.customer_id
),
classified AS (
	SELECT *, NTILE(3) OVER (ORDER BY revenue DESC) AS tile
	FROM customer_revenue
),
segment_revenue AS (
	SELECT customer_id, revenue, CASE 
		WHEN tile = 1 THEN "High value"
        WHEN tile = 2 THEN "Medium value"
        ELSE "Low value" 
        END AS segment
	FROM classified
	GROUP BY customer_id
)
SELECT
    segment, SUM(revenue) AS revenue, ROUND(SUM(revenue)/ SUM(SUM(revenue)) OVER() * 100, 2) AS revenue_pct
FROM segment_revenue
GROUP BY segment
ORDER BY revenue_pct DESC;
```
| segment | revenue | revenue_pct |
|------------|-----------|-----------|
| High Value | 1614196 | 45.85 |
| Medium Value | 1151002 | 32.69 |
| Low Value | 755786 | 21.47 |

3. RFM Analysis
```sql
WITH max_order_date AS (
	SELECT MAX(order_date) as global_last_date FROM orders
),
customer_metrics AS (
	SELECT o.customer_id, COUNT(DISTINCT o.order_id) AS frequency,
			SUM(o.quantity*p.price) AS monetary,
            MAX(o.order_date) AS last_order_date
	FROM orders AS o
    JOIN products AS p ON o.product_id = p.product_id
    GROUP BY o.customer_id
)
SELECT c.customer_id, c.frequency, c.monetary, DATEDIFF(m.global_last_date, c.last_order_date) AS recency
FROM customer_metrics AS c
CROSS JOIN max_order_date AS m
LIMIT 3;
```
| customer_id | frequency | monetary | recency |
|------------|-----------|-----------|----------|
|C001|	5|	9095|	124|
|C002|	8|	23860|	53|
|C003|	10|	34871|	51|

4. Product classification by their performance
```sql
WITH product_performance AS (
	SELECT p.product_id, p.product_name, COUNT(o.order_id) AS order_count, SUM(o.quantity*p.price) AS revenue
    FROM orders AS o
    JOIN products AS p ON o.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
    ORDER BY p.product_id 
),
avg_values AS (
	SELECT AVG(order_count) AS avg_order, AVG(revenue) AS avg_revenue
    FROM product_performance
)
SELECT pp.product_id, pp.product_name, order_count, revenue,
	CASE WHEN order_count >= avg_order AND revenue >= avg_revenue THEN "Hero product"
		 WHEN order_count >= avg_order AND revenue < avg_revenue THEN "Traffic driver"
         WHEN order_count < avg_order AND revenue >= avg_revenue THEN "Profit genarator"
         ELSE "Underperforming"
         END AS product_type
FROM product_performance AS pp
CROSS JOIN avg_values;
```
| product_id | product_name | order_count | product_type |
|------------|-----------|-----------|----------|
|1|	Magnam Set|	19|	121905|	Hero product|
|2|	Voluptas Box|	7|	9261|	Underperforming|
|3|	Eius Gift|	17|	85904|	Hero product|

5. Percent of late orders compared to total orders
```sql
WITH delivery_stats AS (
	SELECT o.order_id, DATEDIFF(o.delivery_date, o.order_date) AS delivery_time
    FROM orders AS o
    WHERE o.delivery_date IS NOT NULL
),
avg_delivery AS (
	SELECT AVG(DATEDIFF(delivery_date, order_date)) AS avg_delivery_days
    FROM orders AS o
),
order_metrics AS (
	SELECT COUNT(*) AS order_total, 
            SUM(CASE WHEN ds.delivery_time > ad.avg_delivery_days THEN 1 ELSE 0 END) AS late_orders
	FROM delivery_stats AS ds 
    CROSS JOIN avg_delivery AS ad
)
SELECT late_orders, order_total, ROUND(late_orders/order_total*100,2) AS late_order_pct
FROM order_metrics;
```
| late_orders | order_total | late_order_pct | 
|------------|-----------|-----------|
|493|	1000|	49.3|	
# Insights
The revenue of FNP relies on most of 3 main categories, including Sweets, Colors and Soft Toys.
