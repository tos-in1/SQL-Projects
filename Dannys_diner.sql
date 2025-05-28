-- Creating of the schema danny_dimer to accomodate the different tables

CREATE SCHEMA dannys_diner;

-- Creating of the 3 different tables....Sales, menu and members

CREATE TABLE sales(
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER);

CREATE TABLE menu(
product_id INTEGER,
product_name TEXT,
price INTEGER);

CREATE TABLE members(
customer_id VARCHAR(1),
join_date DATE);

-- Now time to insert values into tables
-- Sales Table
INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	('1', 'sushi', '10'),
	('2', 'curry', '15'),
	('3', 'ramen', '12');
    
-- inserting into members table

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');
    
 -- Checking column to make sure of the input
SELECT *
FROM 
	menu;
    
SELECT *
FROM 
	sales;

SELECT *
FROM 
	members;

-- Solutions to business questions

-- 1. What is the total amount each customer spent at the restaurant?
-- Using inner join to connect sales table and menu table
SELECT 
	s.customer_id,
    SUM(m.price) AS total_spent
FROM 
	sales AS s
INNER JOIN
	menu AS m
    ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
-- using distinct so as to count unique days and not number of times each 
-- customer enter the restaurant
SELECT 
	customer_id,
    COUNT(DISTINCT order_date) AS day_count
FROM 
	sales
GROUP BY
	customer_id;
    
-- 3. What was the first item from the menu purchased by each customer?
SELECT
	s.customer_id,
    s.order_date,
    m.product_name
FROM(
	SELECT *,
		ROW_NUMBER () OVER(
		PARTITION BY customer_id
		ORDER BY order_date ASC) AS ranked
	FROM 
		sales) AS s -- using subquery to first figure out the earliest sales date
INNER JOIN
	menu AS m
    ON s.product_id = m.product_id
Where 
	s.ranked = 1;
    
-- 4. What is the most purchased item on the menu 
-- and how many times was it purchased by all customers?
SELECT
	m.Product_name,
    COUNT(s.product_id) AS NO_of_purchase
FROM
	sales AS s
INNER JOIN
	menu AS m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY NO_of_purchase DESC;
    
-- 5. Which item was the most popular for each customer?
-- first, have an inner query count each item bought by a customer and assign it ranking	
SELECT
	ranked.customer_id,
    ranked.product_name
FROM(
	SELECT
		s.customer_id,
		m.product_name,
		COUNT(*) AS total_count,
		RANK () OVER(
		PARTITION BY s.customer_id
		ORDER BY  COUNT(*) DESC) AS rnk
	FROM sales AS s
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name) AS ranked
WHERE
	rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member
SELECT
	ranked.customer_id,
    ranked.product_name,
    ranked.order_date
FROM(
	SELECT
		s.customer_id,
		m.product_name,
		s.order_date,
		RANK () OVER(
		PARTITION BY customer_id
		ORDER BY order_date DESC) AS rnk
	FROM
		sales AS s
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	INNER JOIN members AS me
		ON s.customer_id = me.customer_id
	WHERE s.order_date < me.join_date) AS ranked
WHERE
	rnk = 1;
    
-- 7. Which item was purchased just before the customer became a member?
-- still using the same windows function just like question 6 but doing 
-- the opposite
SELECT
	ranked.customer_id,
    ranked.product_name,
    ranked.order_date
FROM(
	SELECT
		s.customer_id,
		m.product_name,
		s.order_date,
		RANK () OVER(
		PARTITION BY customer_id
		ORDER BY order_date ASC) AS rnk
	FROM
		sales AS s
	INNER JOIN menu AS m
		ON s.product_id = m.product_id
	INNER JOIN members AS me
		ON s.customer_id = me.customer_id
	WHERE s.order_date >= me.join_date) AS ranked
WHERE
	rnk = 1;

-- 8. What is the total items and amount spent for each member before they 
-- became a member?

SELECT
	s.customer_id,
    COUNT(*) AS item_count,
    SUM(m.price) AS amount_spent
FROM
	sales AS s
INNER JOIN
	menu AS m
    ON s.product_id = m.product_id
INNER JOIN
	members AS me
    ON s.customer_id = me.customer_id
WHERE s.order_date < me.join_date
GROUP BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier
--  how many points would each customer have?
SELECT
	s.customer_id,
	SUM(
		CASE
			WHEN m.product_name = 'sushi' THEN 20 * m.price
			ELSE 10 * m.price
			END) AS points
FROM
	sales AS s
INNER JOIN menu AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do 
-- customer A and B have at the end of January?
SELECT
  s.customer_id,
  SUM(
    CASE
      -- 2x points on everything during 1 week welcome period (including join date)
      WHEN s.order_date BETWEEN me.join_date AND DATE_ADD(me.join_date, INTERVAL 6 DAY)
        THEN m.price * 20
      -- normal points outside of the 1 week
      ELSE m.price * 10
    END
  ) AS total_points
FROM 
	sales AS s
INNER JOIN menu AS m 
	ON s.product_id = m.product_id
INNER JOIN members AS me
	ON s.customer_id = me.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

-- BONUS QUESTION
-- recreating of table outputs as show by danny
SELECT
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE
		WHEN (s.customer_id = 'A' AND s.order_date >= '2021-01-07') OR
			(s.customer_id = 'B' AND s.order_date >= '2021-01-09')
		THEN 'Y'
		ELSE 'N'
	END AS members
FROM
	sales AS s
LEFT JOIN menu AS m 
	ON s.product_id = m.product_id;
