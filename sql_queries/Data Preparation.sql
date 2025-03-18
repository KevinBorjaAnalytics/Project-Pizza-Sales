-- DATA CLEANING
-- 1. REMOVE DUPLICATES
-- no duplicates found
WITH duplicate_cte AS (
	SELECT *, ROW_NUMBER() OVER (
    PARTITION BY order_details_id, order_id, pizza_id, quantity, order_date, order_time,
    unit_price, total_price, pizza_size, pizza_category, pizza_ingredients, pizza_name) AS row_num
    FROM pizza_sales
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- 2.STANDARDIZE DATA
UPDATE pizza_sales SET order_date = STR_TO_DATE(order_date, '%d/%m/%Y');
ALTER TABLE pizza_sales MODIFY order_date DATE;

UPDATE pizza_sales SET order_time = STR_TO_DATE(order_time, '%H:%i:%s');
ALTER TABLE pizza_sales MODIFY order_time TIME;

ALTER TABLE pizza_sales MODIFY unit_price DECIMAL(10, 2);
ALTER TABLE pizza_sales MODIFY total_price DECIMAL(10, 2);

-- 3.NORMALIZE DATA 
CREATE TABLE Orders (
    order_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL
);

CREATE TABLE Pizzas (
    pizza_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    pizza_name VARCHAR(50) NOT NULL,
    pizza_size VARCHAR(50) NOT NULL,
    pizza_category VARCHAR(100) NOT NULL,
    pizza_ingredients TEXT NOT NULL
);

CREATE TABLE OrderDetails (
    order_details_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    pizza_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (pizza_id) REFERENCES Pizzas(pizza_id)
);

INSERT INTO Orders (order_date, order_time)
SELECT order_date, order_time
FROM pizza_sales;

INSERT INTO Pizzas (pizza_name, pizza_size, pizza_category, pizza_ingredients)
SELECT pizza_name, pizza_size, pizza_category, pizza_ingredients
FROM pizza_sales;

INSERT INTO OrderDetails (order_id, pizza_id, quantity, unit_price, total_price)
SELECT 
    o.order_id, 
    p.pizza_id, 
    ps.quantity, 
    ps.unit_price,
    ps.total_price
FROM pizza_sales ps
JOIN Orders o ON ps.order_details_id = o.order_id
JOIN Pizzas p ON ps.order_details_id = p.pizza_id;

-- 4.TRANSFORM DATA
-- Rename values for visualization purposes
UPDATE Pizzas
SET pizza_size =
	CASE
		WHEN pizza_size = 'S' THEN 'Small'
        WHEN pizza_size = 'M' THEN 'Medium'
        WHEN pizza_size = 'L' THEN 'Large'
        WHEN pizza_size = 'XL' THEN 'XLarge'
        WHEN pizza_size = 'XXL' THEN 'XXLarge'
	END;

-- Add days_of_week column to Orders
ALTER TABLE Orders
ADD COLUMN days_of_week VARCHAR(20);

UPDATE Orders
SET days_of_week = DAYNAME(order_date)
WHERE order_id IS NOT NULL;

-- Add times_of_day column to Orders
ALTER TABLE orders
ADD COLUMN times_of_day VARCHAR(20);

UPDATE Orders
SET times_of_day = (
	CASE 
		WHEN order_time BETWEEN '00:00:00' AND '11:59:59' THEN 'Morning' 
		WHEN order_time BETWEEN '12:00:00' AND '14:59:59' THEN 'Lunch'
		WHEN order_time BETWEEN '15:00:00' AND '17:59:59' THEN 'Afternoon' 
		WHEN order_time BETWEEN '18:00:00' AND '20:59:59' THEN 'Dinner'
		WHEN order_time BETWEEN '21:00:00' AND '23:59:59' THEN 'Late Evening' 
	END)
WHERE order_id IS NOT NULL;

# Add day_category column to Orders
ALTER TABLE Orders
ADD COLUMN day_category VARCHAR(20);

UPDATE Orders
SET day_category = CASE
    WHEN days_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday') THEN 'Weekday'
    WHEN days_of_week IN ('Saturday', 'Sunday') THEN 'Weekend'
END;

-- 5. REMOVE UNNECESSARY DATA
DROP TABLE pizza_sales;