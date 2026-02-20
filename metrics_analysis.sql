-- DATA QUALITY
-- How many orders that have 0 quantity
SELECT COUNT(DISTINCT order_id) as order_count, 
		ROUND(100*COUNT(DISTINCT order_id)/ (SELECT COUNT(DISTINCT order_id) FROM orders),2) AS pct_invalid
FROM orders
WHERE quantity <= 0;

-- The percentage of 1-time buyers
WITH customer_orders AS (
	SELECT DISTINCT customer_id, COUNT(DISTINCT order_id) AS total_orders
	FROM orders AS o
    GROUP BY customer_id
)
SELECT ROUND(100*SUM( CASE WHEN total_orders = 1 THEN 1 ELSE 0 END)/ COUNT(*),2) AS one_time_buyer_percent
FROM customer_orders; 

-- BUSINESS METRICS
-- Average order value
SELECT ROUND(SUM(o.quantity*p.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders AS o
LEFT JOIN products AS p ON o.product_id = p.product_id;

-- Repeat purchase rate
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

-- CUSTOMER BEHAVIOUR
-- Customer segmentation and revenue for each segment
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

-- RFM
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
CROSS JOIN max_order_date AS m;

-- Percent of customer who hasn't shopped more than 50 days
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
),
rfm AS (
	SELECT c.customer_id, c.frequency, c.monetary, DATEDIFF(m.global_last_date, c.last_order_date) AS recency
	FROM customer_metrics AS c
	CROSS JOIN max_order_date AS m
)
SELECT ROUND(SUM(CASE WHEN recency>50 THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS risk_churn
FROM rfm;

-- PRODUCT PERFORMANCE
-- Sales and percent of revenue by category
WITH category_revenue AS (
	SELECT p.category , SUM(o.quantity*p.price) AS total_sales
	FROM orders AS o
	JOIN products AS p ON o.product_id = p.product_id
	GROUP BY p.category 
	ORDER BY total_sales DESC
)
SELECT category, total_sales, ROUND(100*total_sales/SUM(total_sales) OVER(),2) AS revenue_pct
FROM category_revenue;

-- Product classification by their performance
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

-- Regional performance
-- Cateogory spending by cities
WITH region_revenue AS (
	SELECT c.city, p.category, SUM(o.quantity*p.price) AS revenue
	FROM orders AS o
	JOIN products AS p ON o.product_id = p.product_id
	JOIN customers AS c ON c.customer_id = o.customer_id
	GROUP BY c.city, p.category
	ORDER BY c.city DESC
)
SELECT city, category, revenue, ROUND(revenue/SUM(revenue) OVER(PARTITION BY city)*100,2) AS category_spending_pct
FROM region_revenue
ORDER BY city, category_spending_pct DESC;

-- Delivery time rate by region
WITH delivery_stats AS (
	SELECT c.city, DATEDIFF(o.delivery_date, o.order_date) AS delivery_time
    FROM orders AS o
    JOIN customers AS c ON o.customer_id = c.customer_id
    WHERE o.delivery_date IS NOT NULL
),
region_delivery AS (
	SELECT city, COUNT(*) AS total_orders, ROUND(AVG(delivery_time),2) AS avg_delivery_time,
		SUM(CASE WHEN delivery_time > 7 THEN 1 ELSE 0 END) AS late_orders
	FROM delivery_stats
    GROUP BY city
),
region_late_delivery AS (
	SELECT city, total_orders, late_orders, avg_delivery_time, ROUND(late_orders/total_orders*100,2) AS late_delivery_rate
	FROM region_delivery
	ORDER BY late_delivery_rate DESC
)
SELECT ROUND(SUM(CASE WHEN late_delivery_rate > 50 THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS city_delivery_rate_pct
FROM region_late_delivery;

-- Percent of late orders compared to total orders
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
SELECT late_orders, order_total, ROUND(late_orders/order_total*100,2) AS late_order_rate
FROM order_metrics;
