
select * FROM orders;

DESCRIBE orders;

ALTER TABLE customers
MODIFY Customer_ID VARCHAR(50),
MODIFY `Name` VARCHAR(255),
MODIFY City VARCHAR(100),
MODIFY Contact_Number VARCHAR(15),
MODIFY Email VARCHAR(100),
MODIFY Gender VARCHAR(10);

ALTER TABLE customers
RENAME COLUMN `Customer_ID` TO customer_id,
RENAME COLUMN  `Name` TO customer_name,
RENAME COLUMN City TO city,
RENAME COLUMN Contact_Number TO customer_phone;

ALTER TABLE Products
MODIFY `Product_Name` VARCHAR(255),
MODIFY Category VARCHAR(100),
MODIFY Occasion VARCHAR(100);

ALTER TABLE Products
RENAME COLUMN `Product_ID` TO product_id,
RENAME COLUMN  `Product_Name` TO product_name,
RENAME COLUMN Category TO category,
RENAME COLUMN `PRICE (INR)` TO price,
RENAME COLUMN Occasion TO occasion,
RENAME COLUMN `Description` TO `description`;

ALTER TABLE orders
MODIFY Customer_ID VARCHAR(100),
MODIFY Order_Time TIME,
MODIFY Delivery_Time TIME;

ALTER TABLE orders
RENAME COLUMN  `Order_ID` TO order_id,
RENAME COLUMN  `Customer_ID` TO customer_id,
RENAME COLUMN  `Product_ID` TO product_id,
RENAME COLUMN  `quantity` TO quantity,
RENAME COLUMN  `Order_Date` TO order_date,
RENAME COLUMN  `Order_Time` TO order_time,
RENAME COLUMN  `Delivery_Date` TO delivery_date,
RENAME COLUMN  `Delivery_Time` TO delivery_time;

ALTER TABLE orders
ADD COLUMN order_date_clean DATE;
UPDATE orders
SET order_date_clean = STR_TO_DATE(order_date, '%d-%m-%Y');

SET SQL_SAFE_UPDATES = 0;

SELECT order_date, order_date_clean
FROM orders
LIMIT 20;

ALTER TABLE orders DROP COLUMN order_date;
ALTER TABLE orders CHANGE order_date_clean order_date DATE;

ALTER TABLE orders
ADD COLUMN delivery_date_clean DATE;
UPDATE orders
SET delivery_date_clean = STR_TO_DATE(delivery_date, '%d-%m-%Y');

SELECT delivery_date, delivery_date_clean
FROM orders
LIMIT 20;

ALTER TABLE orders DROP COLUMN delivery_date;
ALTER TABLE orders CHANGE delivery_date_clean delivery_date DATE;

select * from orders;
describe orders;







