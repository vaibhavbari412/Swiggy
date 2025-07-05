
# 🛵 Swiggy Advanced Business Analytics with SQL  
> 📍 Solving 20 real-world business problems using SQL on a Snowflake-inspired schema

![Project Banner](./A_2D_digital_illustration_banner_for_a_SQL_project.png)

---

## 🚀 About the Project
I stepped into the role of a **Data Analyst** for Swiggy, built a **Snowflake-inspired normalized schema**, and solved **20 advanced business problems** using PostgreSQL to help drive data-driven decisions in marketing, operations, and product strategy.

---

## 🧊 Schema Design
Built using best practices of a Snowflake-inspired schema (high normalization):

![ERD](./Swiggy%20ERD.png)

📌 Tables:  
- `customers`
- `restaurants`
- `orders`
- `deliveries`
- `riders`

> See full schema in [`SWIGGY SCHEMA.sql`](./SWIGGY%20SCHEMA.sql)

---

## 🧠 Key Business Problems & SQL Solutions

Below are **15 of the 20** advanced business problems solved:  
*(Full queries 👉 [`Swiggy_Analysis.sql`](./Swiggy_Analysis.sql))*

---

### 🍜 1️⃣ Top 5 Most Ordered Dishes by "Arjun Mehta"
```sql
SELECT order_item, COUNT(order_id) AS total_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_name = 'Arjun Mehta'
  AND order_date >= CURRENT_DATE - INTERVAL '1 YEAR'
GROUP BY order_item
ORDER BY total_orders DESC
LIMIT 5;
```
✅ *Focus marketing on customer favorites.*

---

### 🕒 2️⃣ Popular Order Time Slots (2-hour intervals)
```sql
SELECT FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_hour, COUNT(*) AS total_orders
FROM orders
GROUP BY start_hour
ORDER BY total_orders DESC;
```
✅ *Optimize delivery fleet during peak times.*

---

### 💰 3️⃣ High-Value Customers (> ₹100K)
```sql
SELECT c.customer_name, SUM(o.total_amount) AS total_spent
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING SUM(o.total_amount) > 100000
ORDER BY total_spent DESC;
```
✅ *Personalize offers to retain top spenders.*

---

### 📉 4️⃣ Customer Churn (Ordered in 2023, not in 2024)
```sql
(SELECT customer_id FROM orders WHERE EXTRACT(YEAR FROM order_date)=2023)
EXCEPT
(SELECT customer_id FROM orders WHERE EXTRACT(YEAR FROM order_date)=2024);
```
✅ *Target churned users with win-back campaigns.*

---

### 🏆 5️⃣ Restaurant Revenue Ranking by City
```sql
SELECT restaurant_name, city, SUM(total_amount) AS revenue,
  DENSE_RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC) AS rank
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
GROUP BY restaurant_name, city
ORDER BY city, rank;
```
✅ *Identify city-wise top performing restaurants.*

---

### 🍲 6️⃣ Most Popular Dish by City
```sql
SELECT city, order_item, COUNT(*) AS total_orders
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY city, order_item
ORDER BY city, total_orders DESC;
```
✅ *Helps design regional menus.*

---

### 🚚 7️⃣ Orders Placed but Not Delivered
```sql
SELECT r.restaurant_name, r.city, COUNT(*) AS undelivered_orders
FROM orders o
JOIN deliveries d ON o.order_id = d.order_id
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE d.delivery_status = 'Not Delivered'
GROUP BY r.restaurant_name, r.city
ORDER BY undelivered_orders DESC;
```
✅ *Reduce cancellations by improving delivery ops.*

---

### ⏱️ 8️⃣ Rider Average Delivery Time
```sql
SELECT d.rider_id,
  ROUND(AVG(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time))/60),2) AS avg_minutes
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
WHERE d.delivery_status='Delivered'
GROUP BY d.rider_id;
```
✅ *Identify fast & slow riders for training.*

---

### 📈 9️⃣ Monthly Growth Ratio for Restaurants
```sql
WITH monthly_orders AS (
  SELECT restaurant_id, TO_CHAR(order_date,'MM-YY') AS month, COUNT(*) AS orders
  FROM orders o
  JOIN deliveries d ON o.order_id = d.order_id
  WHERE d.delivery_status='Delivered'
  GROUP BY restaurant_id, month
)
SELECT restaurant_id, month,
  ROUND((orders - LAG(orders) OVER(PARTITION BY restaurant_id ORDER BY month))::NUMERIC / 
        LAG(orders) OVER(PARTITION BY restaurant_id ORDER BY month) * 100,2) AS growth_ratio
FROM monthly_orders;
```
✅ *Spot restaurants with rising or falling sales.*

---

### ⭐ 🔟 Rider Ratings Analysis
```sql
WITH delivery_times AS (
  SELECT rider_id,
    ROUND(EXTRACT(EPOCH FROM (delivery_time - order_time))/60,2) AS time_min
  FROM deliveries d
  JOIN orders o ON d.order_id = o.order_id
  WHERE d.delivery_status='Delivered'
)
SELECT rider_id,
  CASE
    WHEN time_min < 15 THEN '5 Star'
    WHEN time_min BETWEEN 15 AND 20 THEN '4 Star'
    ELSE '3 Star' END AS rating,
  COUNT(*) AS total
FROM delivery_times
GROUP BY rider_id, rating
ORDER BY rider_id;
```
✅ *Understand service quality.*

---

### 📦 1️⃣1️⃣ Rider Monthly Earnings (8% commission)
```sql
SELECT d.rider_id, TO_CHAR(o.order_date,'MM-YY') AS month,
  SUM(o.total_amount) * 0.08 AS monthly_earning
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
GROUP BY d.rider_id, month
ORDER BY d.rider_id, month;
```
✅ *Financial tracking for riders.*

---

### 📊 1️⃣2️⃣ Monthly Sales Trends
```sql
WITH monthly_sales AS (
  SELECT EXTRACT(MONTH FROM order_date) AS month, SUM(total_amount) AS sales
  FROM orders
  GROUP BY month
)
SELECT month, sales,
  LAG(sales) OVER(ORDER BY month) AS prev_sales,
  ROUND((sales - LAG(sales) OVER(ORDER BY month))::NUMERIC / LAG(sales) OVER(ORDER BY month) * 100,2) AS growth_pct
FROM monthly_sales;
```
✅ *Detect seasonality & trends.*

---

### 🧊 1️⃣3️⃣ Customer Segmentation (Gold vs Silver)
```sql
WITH cust AS (
  SELECT customer_id, SUM(total_amount) AS spend
  FROM orders
  GROUP BY customer_id
)
SELECT customer_id,
  CASE WHEN spend > (SELECT AVG(total_amount) FROM orders) THEN 'Gold' ELSE 'Silver' END AS segment
FROM cust;
```
✅ *Personalized marketing campaigns.*

---

### 🏙️ 1️⃣4️⃣ City Revenue Ranking (for 2023)
```sql
SELECT r.city, SUM(o.total_amount) AS revenue,
  RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS rank
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE EXTRACT(YEAR FROM o.order_date)=2023
GROUP BY r.city;
```
✅ *Focus strategy on top cities.*

---

## 📂 Project Structure
```
📦 Swiggy_SQL_Project
├── Swiggy Business problems.pdf
├── Swiggy ERD.png
├── A_2D_digital_illustration_banner_for_a_SQL_project.png
├── SWIGGY SCHEMA.sql
├── Swiggy_Analysis.sql
└── README.md
```

---

## 🖼️ Add Visuals & Branding
- Project banner:  
  `![Banner](./A_2D_digital_illustration_banner_for_a_SQL_project.png)`
- ERD diagram:  
  `![ERD](./Swiggy%20ERD.png)`
- Optional dashboard / GIF:  
  `![Dashboard](./dashboard.png)`

---

## ✏️ Learnings & Highlights
✔ Advanced SQL: window functions, CTEs, ranking, EXCEPT  
✔ Designed Snowflake-inspired schema  
✔ Explained business impact of each query  
✔ Data storytelling for stakeholders

---

## 📢 *Like this project?*
Give it a ⭐ star!  
📧 **vaibhavbari412@gmail.com** | [LinkedIn](https://www.linkedin.com/in/your-profile)

> *Data storytelling makes your GitHub shine!*
