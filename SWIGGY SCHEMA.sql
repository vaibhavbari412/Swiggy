--Creating the table based on Normalised data

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(255),
	reg_date DATE
);

CREATE TABLE restaurants
(
	restaurant_id INT PRIMARY KEY,
	restaurant_name VARCHAR(255),
	city VARCHAR(50),
	opening_hours VARCHAR(55)
);
--SELECT * from restaurants

CREATE TABLE riders
(
	rider_id INT PRIMARY KEY,
	rider_name VARCHAR(255),
	sign_up DATE
);

CREATE TABLE orders
(
	order_id INT PRIMARY KEY,
	customer_id INT REFERENCES customers(customer_id),
	restaurant_id INT REFERENCES restaurants(restaurant_id),
	order_item VARCHAR(255),
	order_date DATE,
	order_time TIME,
	order_status VARCHAR(255),
	total_amount FLOAT
);
--DROP TABLE IF EXISTS deliveries
CREATE TABLE deliveries
(
	delivery_id INT PRIMARY KEY,
	order_id INT REFERENCES orders(order_id),
	delivery_status VARCHAR(50),
	delivery_time TIME,
	rider_id INT REFERENCES riders(rider_id)
);


SELECT 'Tables created successfully!'