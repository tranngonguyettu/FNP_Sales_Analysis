-- SALES OVERVIEW
-- Total revenue
SELECT SUM(o.quantity*p.price) AS total_sales
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id;

-- Sales by occasions
SELECT o.Occasion, SUM(o.quantity*p.price) AS total_sales
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id
GROUP BY o.Occasion
ORDER BY total_sales DESC;

-- Sales by months
SELECT DATE_FORMAT(order_date,'%Y-%m') AS month, SUM(o.quantity*p.price) AS total_sales
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id
GROUP BY month
ORDER BY month;

-- Sales by category
SELECT p.category , SUM(o.quantity*p.price) AS total_sales
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id
GROUP BY p.category 
ORDER BY total_sales DESC;

-- Total orders
SELECT COUNT(*) AS order_count
FROM orders;

-- Average order-delivery days
SELECT AVG(DATEDIFF(delivery_date, order_date)) AS avg_delivery_days
FROM orders;

-- PRODUCT ANALYSIS
-- Top 10 ordered products
SELECT p.product_name, SUM(o.quantity) as total_sold
FROM products as p
LEFT JOIN orders AS o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC
LIMIT 10;

-- Top 10 products with high revenue
SELECT p.product_name, SUM(o.quantity*p.price) AS total_revenue
FROM products as p
LEFT JOIN orders AS o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Least ordered products
SELECT p.product_name, SUM(o.quantity) as total_sold
FROM products as p
LEFT JOIN orders AS o ON p.product_id = o.product_id
GROUP BY p.product_name
ORDER BY total_sold ASC
LIMIT 5;

-- TIME ANALYSIS
-- Sales by weekdays
SELECT 
  DAYNAME(order_date) AS weekday,
  SUM(o.quantity*p.price) AS total_revenue
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id
GROUP BY weekday
ORDER BY total_revenue DESC;

-- Sales by order hours
SELECT 
  HOUR(order_time) AS hour_of_day,
  SUM(o.quantity*p.price) AS total_revenue
FROM orders AS o
JOIN products AS p ON o.product_id = p.product_id
GROUP BY hour_of_day
ORDER BY total_revenue DESC;

-- CUSTOMER ANAYLYSIS
-- Top customers by number of orders
SELECT DISTINCT c.customer_id, COUNT(*) AS total_orders
FROM orders AS o
RIGHT JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_orders DESC;

-- Top customer contributing most to revenue
SELECT DISTINCT c.customer_id, SUM(o.quantity*p.price) AS total_revenue
FROM orders AS o
RIGHT JOIN customers AS c ON o.customer_id = c.customer_id
JOIN products AS p ON p.product_id = o.product_id
GROUP BY c.customer_id
ORDER BY total_revenue DESC;

-- Average customer spendings
SELECT 
  ROUND(SUM(o.quantity*p.price)/COUNT(DISTINCT order_id),2) AS avg_order_value
FROM orders AS o
JOIN products AS p ON p.product_id = o.product_id;

-- Repeat customers
SELECT DISTINCT c.customer_id, COUNT(*) AS total_orders
FROM orders AS o
RIGHT JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING total_orders > 10;

-- ADVANCED ANALYSIS
-- Proportion of categories
SELECT p.category, ROUND(SUM(o.quantity * p.price),2) AS category_revenue, ROUND(
        SUM(o.quantity * p.price)/ SUM(SUM(o.quantity * p.price)) OVER() * 100,2) AS revenue_pct
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue_pct DESC;

-- How many % of revenue that repeat customers accounts for
WITH loyal_customers AS (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) >= 10
)
SELECT 
    ROUND(100.0 * SUM(
            CASE WHEN o.customer_id IN (SELECT customer_id FROM loyal_customers)
					THEN p.price * o.quantity ELSE 0
            END)/ SUM(p.price * o.quantity),2) AS loyal_revenue_percent
FROM orders o
JOIN products p ON o.product_id = p.product_id;

