-- Q1. Top 5 Most Frequently Ordered Dishes
 -- Question:
 -- Write a query to find the top 5 most frequently ordered dishes by the customer "Arjun Mehta" in
 -- the last 1 year.

SELECT 
	order_item,
	count (order_id) as total_orders
FROM
	orders o 
INNER JOIN 
	customers c 
ON c.customer_id = o.customer_id
where c.customer_name='Arjun Mehta' --AND o.order_date >= CURRENT_DATE- INTERVAL '1 YEAR'
AND O.ORDER_DATE >= DATE '2024-01-24' - INTERVAL '1 YEAR'
group by 1
order by 2 DESC
LIMIT 5;

--We can solve it by rank as well


-- Q2. Popular Time Slots
--  Question:
--  Identify the time slots during which the most orders are placed, based on 2-hour intervals.
--APPROACH 1
SELECT
	CASE 
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 0 AND 1 THEN '0-2'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 2 AND 3 THEN '2-4'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 4 AND 5 THEN '4-6'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 6 AND 7 THEN '6-8'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 8 AND 9 THEN '8-10'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10-12'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12-14'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14-16'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16-18'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18-20'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20-22'
		WHEN EXTRACT (HOUR FROM order_time) BETWEEN 23 AND 24 THEN '22-24'
	END AS time_slot,
	COUNT(*) AS total_orders
FROM
	orders
GROUP BY 1
ORDER BY 2 DESC;

--APPROACH 2

SELECT
	FLOOR(EXTRACT (HOUR FROM order_time)/2) *2 AS start_time,
	FLOOR(EXTRACT (HOUR FROM order_time)/2) *2 + 2 AS end_time,
	count(*) as total_orders
FROM
	orders
group by 1,2
order by 3 desc

-- Q3. Order Value Analysis
--  Question:
--  Find the average order value (AOV) per customer who has placed more than 300
--  orders. Return: customer_name, aov (average order value).
SELECT
	o.customer_id,
	c.customer_name,
	count(order_id) AS total_orders,
	ROUND(AVG(total_amount)::"numeric",2) as aov
FROM
	orders O 
JOIN 
	customers c
ON c.customer_id = O.customer_id
GROUP BY 1,2
HAVING count(order_id) > 300
ORDER BY 3 DESC

-- Q4. High-Value Customers
--  Question:
--  List the customers who have spent more than 100K in total on food
--  orders. Return: customer_name, customer_id.

SELECT
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) as total_amount
FROM
	orders O 
JOIN 
	customers c
ON c.customer_id = O.customer_id
GROUP BY 1,2
HAVING SUM(o.total_amount)>100000
order by 3 desc

-- Q5. Orders Without Delivery
--  Question:
--  Write a query to find orders that were placed but not delivered.
--  Return: restaurant_name, city, and the number of not delivered

SELECT 
	r.restaurant_name, 
	r.city,
	count(*) as total_orders
FROM 
	restaurants r
join 
	orders o 
on r.restaurant_id = o.restaurant_id
join 
	deliveries d
on 
	d.order_id = o.order_id
where
	d.delivery_status ='Not Delivered'
group by 1,2
order by 3 desc

 -- Q6. Restaurant Revenue Ranking
 -- Question:
 -- Rank restaurants by their total revenue from the last year.
 -- Return: restaurant_name, total_revenue, and their rank within their city
WITH ranked_cte
as
		( SELECT
	 	r.restaurant_name,
		 city,
		sum(total_amount) as total_revenue,
		dense_rank() over(partition by city order by sum(total_amount) DESC) as res_rank
	FROM
		restaurants r 
	JOIN 
		orders o
	ON
		r.restaurant_id = o.restaurant_id
	where O.ORDER_DATE >= DATE '2024-01-24' - INTERVAL '1 YEAR'
	GROUP BY restaurant_name,city
	)
SELECT *
from ranked_cte
where res_rank =1 
order by total_revenue DESC

 -- Q7. Most Popular Dish by City
 -- Question:
 -- Identify the most popular dish in each city based on the number of orders.
select 
	city,
	order_item as dish,
	total_count
FROM
	(SELECT
		r.city,
		o.order_item,
		count(o.order_id) as total_count ,
		dense_rank () over (partition by r.city order by count(o.order_id) desc ) as city_rank
	FROM
		orders o
	join
		restaurants r
	on 
		r.restaurant_id = o.restaurant_id
	GROUP BY 1,2) as t
WHERE city_rank =1
order by total_count desc


-- Q8. Customer Churn
--  Question:
--  Find customers who haven’t placed an order in 2024 but did in 2023.
	
(SELECT
	c.customer_id,
	c.customer_name
FROM
	customers c 
join
	orders o
on o.customer_id = c.customer_id
WHERE 
	extract (YEAR FROM order_date) = 2023 )
EXCEPT
(SELECT
	c.customer_id,
	c.customer_name
FROM
	customers c 
join
	orders o
on o.customer_id = c.customer_id
WHERE 
	extract (YEAR FROM order_date) = 2024 )


 -- Q9. Cancellation Rate Comparison
 -- Question:
 -- Calculate and compare the order cancellation rate for each restaurant between the current year
 -- and the previous year.
with cte2023
as 	( SELECT 
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(case when d.delivery_status= 'Not Delivered' THEN 1 END) AS not_delivered,
		round(COUNT(case when d.delivery_status= 'Not Delivered' THEN 1 END)::"numeric"/COUNT(o.order_id) * 100,2) as cancellation_rate_2023
	 FROM
	 	orders o 
	LEFT JOIN 
		deliveries d
	on
		d.order_id = o.order_id
	where EXTRACT(YEAR FROM o.order_date) = 2023
	group by 1
),
cte2024
as
( SELECT 
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(case when d.delivery_status= 'Not Delivered' THEN 1 END) AS not_delivered,
		round(COUNT(case when d.delivery_status= 'Not Delivered' THEN 1 END)::"numeric"/COUNT(o.order_id) * 100,2) as cancellation_rate_2024
	 FROM
	 	orders o 
	LEFT JOIN 
		deliveries d
	on
		d.order_id = o.order_id
	where EXTRACT(YEAR FROM o.order_date) = 2024
	group by 1
)

select 
	a.restaurant_id,
	cancellation_rate_2023,
	cancellation_rate_2024,
	cancellation_rate_2024 - cancellation_rate_2023 as difference
from 
	cte2023 as a
join 
	cte2024 as b
on a.restaurant_id = b.restaurant_id

 -- Q10. Rider Average Delivery Time
 -- Question:
 -- Determine each rider's average delivery time.
SELECT 
	rider_id,
	ROUND(AVG(EXTRACT (EPOCH FROM (delivery_time - order_time + CASE WHEN delivery_time < order_time THEN INTERVAL '1 DAY' 
	ELSE INTERVAL '0 DAY' END)/60)),2) AS avg_time_difference_min
	
FROM 
	orders o 
JOIN 
	deliveries d 
on o.order_id = d.order_id
where d.delivery_status='Delivered'
group by 1
order by 2

-- Q11. Monthly Restaurant Growth Ratio
--  Question:
--  Calculate each restaurant's growth ratio based on the total number of delivered orders since its
--  joining.
WITH total_orders
as
	(SELECT
		o.restaurant_id,
		TO_CHAR(o.order_date,'mm-yy') as month,
		count(o.order_id) as total_order_id,
		LAG(count(o.order_id),1) over (PARTITION BY o.restaurant_id order by TO_CHAR(o.order_date,'mm-yy')) AS prev_month_order
	FROM
		orders o
	Join 
		deliveries d 
	ON 
		d.order_id = o.order_id
	WHERE 
		d.delivery_status ='Delivered'
	group by 1,2
	order by 1,2)
SELECT 
	restaurant_id,
	month,
	round((total_order_id - prev_month_order)::"numeric"/prev_month_order *100, 2) as growth_ratio
FROM 
	total_orders

-- Q12. Customer Segmentation
--  Question:
--  Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the
--  average order value (AOV). If a customer's total spending exceeds the AOV, label them as
--  'Gold'; otherwise, label them as 'Silver'.
--  Return: The total number of orders and total revenue for each segment.
WITH cust_seg
as
	(SELECT 
		customer_id,
		SUM(total_amount) as total_amount_spent,
		COUNT(order_id) as total_orders,
		CASE WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) 
		THEN 'Gold' ELSE 'Silver' END AS Cust_Segmentation
	FROM 
		orders
	group by 1)
SELECT 
	Cust_Segmentation,
	SUM(TOTAL_ORDERS) AS total_orders,
	SUM(total_amount_spent) AS total_amount
FROM
	cust_seg
GROUP BY Cust_Segmentation

-- Q13. Rider Monthly Earnings
--  Question:
--  Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
SELECT 
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') as month,
	SUM(o.total_amount) as total_order_value,
	SUM(o.total_amount) * 8 /100 AS Monthly_Earning
FROM 
	orders o 
JOIN 
	deliveries d
ON 
	d.order_id = o.order_id
GROUP BY 1,2
ORDER BY 1,2

 -- Q14. Rider Ratings Analysis
 -- Question:
 -- Find the number of 5-star, 4-star, and 3-star ratings each rider has.
 -- Riders receive ratings based on delivery time:
 -- ● 5-star: Delivered in less than 15 minutes
 -- ● 4-star: Delivered between 15 and 20 minutes
 -- ● 3-star: Delivered after 20 minutes
WITH CTE 
AS
	(SELECT
		d.rider_id,
		ROUND(EXTRACT (EPOCH FROM (d.delivery_time - o.order_time + CASE WHEN d.delivery_time < o.order_time THEN INTERVAL'1 DAY'
		ELSE INTERVAL '0 DAY' END)/60), 2)AS time_in_min
	FROM 
		orders o 
	JOIN 
		deliveries d
	ON 
		d.order_id = o.order_id
	WHERE d.delivery_status='Delivered'),
CTE2 
AS
	 (SELECT 
	 	rider_id,
		CASE 
		WHEN time_in_min <15 THEN '5 Star'
		WHEN time_in_min >=15 AND time_in_min <=20 THEN '4 Star'
		ELSE '3 Star'
		END AS rating
	FROM CTE)
SELECT
	rider_id,
	rating,
	count(rating) as total_rating
from
	CTE2
GROUP BY 1,2
ORDER BY 1,2

 -- Q15. Order Frequency by Day
 -- Question:
 -- Analyze order frequency per day of the week and identify the peak day for each restaurant.
WITH ranked_cte
AS
	(SELECT
		r.restaurant_id,
		r.restaurant_name,
		TO_CHAR(order_date, 'Day') as day,
		COUNT(order_id) as total_order,
		RANK() OVER (PARTITION BY r.restaurant_id ORDER BY COUNT(order_id) DESC) AS rank
	FROM 
		orders o 
	JOIN
		restaurants r
	ON 
		r.restaurant_id = o.restaurant_id
	GROUP BY 1,2,3)

SELECT 
	restaurant_id,
	restaurant_name,
	day,
	total_order
FROM
	ranked_cte
WHERE rank=1

-- Q16. Customer Lifetime Value (CLV)
--  Question:
--  Calculate the total revenue generated by each customer over all their orders.

SELECT 
	c.customer_id,
	c.customer_name,
	COUNT(order_id) as total_orders,
	SUM(o.total_amount) AS total_revenue
FROM
	orders o
JOIN
	customers c
ON 
	c.customer_id = o.customer_id
GROUP BY 1,2
ORDER BY 4 DESC, 3 DESC

-- Q17. Monthly Sales Trends
--  Question:
--  Identify sales trends by comparing each month's total sales to the previous month.
with cte as
	(SELECT 
		EXTRACT (YEAR FROM order_date) as year,
		EXTRACT (MONTH FROM order_date) as month,
		SUM (total_amount) as curr_month_sale,
		LAG(SUM (total_amount),1) OVER (ORDER BY EXTRACT (YEAR FROM order_date),EXTRACT (MONTH FROM order_date)) AS prev_month_sale
	from
		orders
	GROUP BY 1,2
	ORDER BY 1,2)
select 
	year,
	month,
	ROUND((prev_month_sale -curr_month_sale) ::numeric *100 /prev_month_sale ::NUMERIC,2) as month_ratio
from 
	cte

-- Q18. Rider Efficiency
--  Question:
--  Evaluate rider efficiency by determining average delivery times and identifying those with the
--  lowest and highest averages.
SELECT
	Max(avg_delivery_time) as max_time,
	Min(avg_delivery_time) as min_time
	FROM
	(SELECT
		d.rider_id,
		ROUND (AVG(EXTRACT (EPOCH FROM (d.delivery_time - o.order_time + CASE WHEN delivery_time < order_time THEN INTERVAL '1 DAY' 
		ELSE INTERVAL '0 DAY' END)/60)),2) AS avg_delivery_time
	FROM 
		orders o
	Join 
		deliveries d 
	on 
		d.order_id = o.order_id
	where d.delivery_status ='Delivered'
	GROUP BY 1) as t


 -- Q19. Order Item Popularity
 -- Question:
 -- Track the popularity of specific order items over time and identify seasonal demand spikes.
with season_table
as
	(SELECT 
		order_item,
		EXTRACT(MONTH FROM order_date) as month,
		CASE
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 6 THEN 'Summer'
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 7 AND 10 THEN 'Monsoon'
			ELSE 'Winter'
		END as Seasons
	FROM 
		orders) 
SELECT
	order_item,
	Seasons,
	COUNT(order_item) AS total_orders
FROM 
	season_table
GROUP BY 1,2
ORDER BY 1, 3 DESC


-- Q20. City Revenue Ranking
--  Question:
--  Rank each city based on the total revenue for the last year (2023).

SELECT 
	r.city,
	SUM(total_amount) as total_revenue,
	RANK() OVER ( ORDER BY SUM(total_amount) DESC ) AS rank
FROM
	orders o
JOIN 
	restaurants r
ON 
	r.restaurant_id = o.restaurant_id
WHERE
	EXTRACT (YEAR FROM o.order_date) = 2023
GROUP BY 1






 