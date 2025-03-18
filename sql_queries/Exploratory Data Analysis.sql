-- EXPLORATORY DATA ANALYSIS
-- 1. What days and times do we tend to be busiest?
-- total orders = 48620
SELECT COUNT(order_id) AS total_orders FROM orders;

-- busiest days
SELECT 
    DISTINCT days_of_week,
    COUNT(*) AS total_orders
FROM orders
GROUP BY days_of_week
ORDER BY total_orders DESC;

-- busiest times
SELECT 
	DATE_FORMAT(order_time, '%h %p') AS hour_of_day,
    COUNT(*) AS total_orders
FROM orders
GROUP BY hour_of_day
ORDER BY total_orders DESC;

-- busiest times across the week (day + hour breakdown)
SELECT 
    days_of_week, 
    DATE_FORMAT(order_time, '%h %p') AS hour_of_day, 
    COUNT(*) AS total_orders
FROM orders
GROUP BY days_of_week, hour_of_day
ORDER BY total_orders DESC;

-- Busiest month
SELECT 
    DISTINCT MONTHNAME(order_date) AS months,
    COUNT(*) AS total_orders
FROM orders
GROUP BY months
ORDER BY total_orders DESC;

-- 2. How many pizzas are we making during peak periods?
SELECT
	DISTINCT times_of_day AS peak_periods,
    SUM(od.quantity) AS number_of_pizzas_sold
FROM orders o
JOIN orderdetails od ON o.order_id = od.order_id
GROUP BY times_of_day
ORDER BY number_of_pizzas_sold DESC;

-- 3. What are our best and worst-selling pizzas?
-- Best selling pizzas
SELECT p.pizza_name, 
       SUM(od.quantity) AS total_sold
FROM orderdetails od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_name
ORDER BY total_sold DESC
LIMIT 5;

-- Worst selling pizzas
SELECT p.pizza_name, 
       SUM(od.quantity) AS total_sold
FROM orderdetails od
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY p.pizza_name
ORDER BY total_sold ASC
LIMIT 5;

-- 4. What's our average order value?
SELECT 
    ROUND(SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id), 2) AS average_order_value,
    MIN(unit_price), MAX(unit_price), MAX(unit_price) - MIN(unit_price) AS unit_price_diff
FROM orderdetails od
JOIN orders o ON od.order_id = o.order_id;

-- 5. How well are we utilizing our seating capacity? (we have 15 tables and 60 seats)
-- With the assumption each table serves one order at a time.
SELECT 
    order_date,
    DATE_FORMAT(order_time, '%h %p') AS hours,
    COUNT(DISTINCT order_id) AS total_orders,
    '15' AS total_tables,
    (COUNT(DISTINCT order_id) / 15) * 100 AS estimated_utilization
FROM orders
WHERE order_date = '2015-07-17'
	AND DATE_FORMAT(order_time, '%h %p') = '12 PM'
GROUP BY order_date, hours;

-- With the assumption an average party size per order is 2.5 we can estimate how many seats were occupied
SELECT 
    order_date,
    DATE_FORMAT(order_time, '%h %p') AS hours,
    COUNT(order_id) AS total_orders,
    '60' AS total_seats,
    (COUNT(order_id) * 2.5) AS estimated_seats_used,
    ((COUNT(order_id) * 2.5) / 60) * 100 AS seat_utilization_percentage
FROM orders
WHERE order_date = '2015-07-17'
	AND DATE_FORMAT(order_time, '%h %p') = '12 PM'
GROUP BY order_date, hours;