-- Create the database (if it doesn't exist)
CREATE DATABASE IF NOT EXISTS ecomm;
USE ecomm;

CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    region VARCHAR(50),
    created_at DATE
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    category_id INT,
    price DECIMAL(10,2),
    inventory_count INT,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    status VARCHAR(50),
    total_amount DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_each DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE cart_items (
    cart_item_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    added_at DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
 




-- users
INSERT INTO users VALUES
(1, 'Alice', 'alice@example.com', 'North', '2023-01-15'),
(2, 'Bob', 'bob@example.com', 'South', '2023-02-20'),
(3, 'Charlie', 'charlie@example.com', 'East', '2023-03-12');

-- categories
INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Books'),
(3, 'Fashion');

-- products
INSERT INTO products VALUES
(1, 'Smartphone', 1, 699.00, 100),
(2, 'Laptop', 1, 1200.00, 50),
(3, 'T-shirt', 3, 19.99, 200),
(4, 'Novel', 2, 14.99, 150);

-- orders
INSERT INTO orders VALUES
(101, 1, '2023-04-01', 'Shipped', 733.99),
(102, 2, '2023-04-03', 'Delivered', 1214.99);

-- order_items
INSERT INTO order_items VALUES
(1, 101, 1, 1, 699.00),
(2, 101, 4, 1, 14.99),
(3, 102, 2, 1, 1200.00),
(4, 102, 4, 1, 14.99);

-- payments
INSERT INTO payments VALUES
(5001, 101, '2023-04-01', 733.99, 'Credit Card', 'Completed'),
(5002, 102, '2023-04-03', 1214.99, 'PayPal', 'Completed');

-- reviews
INSERT INTO reviews VALUES
(1, 1, 1, 5, 'Great product!', '2023-04-05'),
(2, 2, 2, 4, 'Good laptop', '2023-04-06');

-- cart_items
INSERT INTO cart_items VALUES
(1, 3, 3, '2023-04-10'),
(2, 3, 2, '2023-04-10');


-- Verify the data
SELECT * FROM users LIMIT 5;
SELECT * FROM categories LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
SELECT * FROM payments LIMIT 5;
SELECT * FROM reviews LIMIT 5;
SELECT * FROM cart_items LIMIT 5;


-- Top 5 Best-selling Products
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 5;

-- Sales Trend by Region
SELECT u.region, MONTH(o.order_date) AS month, SUM(o.total_amount) AS total_sales
FROM orders o
JOIN users u ON o.user_id = u.user_id
GROUP BY u.region, MONTH(o.order_date)
ORDER BY month;

--  Product Rating Report
SELECT p.name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(*) AS review_count
FROM reviews r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.product_id;


-- use of window function 
-- RANK / DENSE_RANK / ROW_NUMBER
-- Rank products by average rating
SELECT 
  p.product_id,
  p.name,
  ROUND(AVG(r.rating), 2) AS avg_rating,
  RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rating_rank
FROM products p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id;

-- LAD/LEAD 
-- Compare each order’s total to previous order by same user
SELECT 
  user_id,
  order_id,
  order_date,
  total_amount,
  LAG(total_amount) OVER (PARTITION BY user_id ORDER BY order_date) AS previous_order_total
FROM orders;

-- SUM / AVG / COUNT (OVER)
-- Running total of revenue by date
SELECT 
  order_date,
  order_id,
  total_amount,
  SUM(total_amount) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM orders;

-- COUNT(*) OVER()
-- See what percent of total each product sold
SELECT 
  product_id,
  SUM(quantity) AS total_sold,
  COUNT(*) OVER() AS total_rows,
  ROUND(100.0 * SUM(quantity) / SUM(SUM(quantity)) OVER (), 2) AS percent_of_total
FROM order_items
GROUP BY product_id;

-- Stored Procedures
-- Daily Sales Summary
DELIMITER //
CREATE PROCEDURE daily_sales_summary(IN report_date DATE)
BEGIN
  SELECT COUNT(*) AS total_orders, SUM(total_amount) AS total_sales
  FROM orders
  WHERE order_date = report_date;
END //
DELIMITER ;
-- Inventory Alert
DELIMITER //
CREATE PROCEDURE low_inventory_alert()
BEGIN
  SELECT name, inventory_count
  FROM products
  WHERE inventory_count < 10;
END //
DELIMITER ;

-- Detecting Fraud Patterns (Basic) Using Logic + Window Functions
SELECT 
  user_id,
  order_id,
  order_date,
  total_amount,
  LAG(total_amount) OVER (PARTITION BY user_id ORDER BY order_date) AS previous_order_amount,
  CASE 
    WHEN total_amount > 2 * LAG(total_amount) OVER (PARTITION BY user_id ORDER BY order_date)
    THEN 'Potential Fraud'
    ELSE 'Normal'
  END AS fraud_flag
FROM orders;

