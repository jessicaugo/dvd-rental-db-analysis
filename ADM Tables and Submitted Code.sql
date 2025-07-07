-- "What are the top 10 cities in terms of sales?"

-- Part B
-- DATE TRANSFORMATION FUNCTION
CREATE OR REPLACE FUNCTION sale_date(payment_date timestamp)
	RETURNS date
	LANGUAGE plpgsql
AS
$$
DECLARE date_only date;
BEGIN
	SELECT payment_date::DATE INTO date_only;
	RETURN date_only;
END;
$$

SELECT sale_date('2007-02-15 22:25:46.996577');

-- Part C
-- CREATE DETAILED TABLE
CREATE TABLE detailed_table (
	payment_id int,
	amount numeric(5,2),
	city varchar(50),
	country varchar(50),
	sale_date date,
	PRIMARY KEY(payment_id)
);

DROP TABLE detailed_table;
SELECT * FROM detailed_table;

-- CREATE SUMMARY TABLE
CREATE TABLE summary_table (
	city varchar(50),
	total_sales_for_city numeric(5,2)
);

DROP TABLE summary_table;
SELECT * FROM summary_table;

-- Part D
-- FILL DETAILED TABLE WITH DATA FROM SOURCE DATABASE
INSERT INTO detailed_table
SELECT 
	p.payment_id,
	p.amount,
	ci.city,
	co.country,
	sale_date(p.payment_date) -- Transformation function from Part B
FROM payment p
INNER JOIN customer cu
ON p.customer_id = cu.customer_id
INNER JOIN address a
ON cu.address_id = a.address_id
INNER JOIN city ci
ON a.city_id = ci.city_id
INNER JOIN country co
ON ci.country_id = co.country_id;

SELECT * FROM detailed_table;

-- Part E
-- CREATE TRIGGER THAT UPDATES SUMMARY TABLE WHEN DATA IS ADDED TO DETAIL TABLE
-- Part 1: Create trigger function
CREATE OR REPLACE FUNCTION trigger_function_insert()
	RETURNS trigger
	LANGUAGE plpgsql
AS
$$
BEGIN
	DELETE FROM summary_table;
	INSERT INTO summary_table
	SELECT 
		city, 
		SUM(amount)
	FROM detailed_table
	GROUP BY city
	ORDER BY 2 DESC
	LIMIT 10;
	RETURN NEW;
END;
$$

-- Part 2: Create trigger statement
CREATE TRIGGER update_summary_table
AFTER INSERT
ON detailed_table
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_function_insert();

-- test trigger
DROP TRIGGER IF EXISTS update_summary_table ON detailed_table;
SELECT * FROM detailed_table;
SELECT * FROM summary_table;
INSERT INTO detailed_table VALUES (169963, 499.99, 'Detroit', 'United States', '2007-02-15 22:25:46.996577');

-- Part F
-- STORED PROCEDURE to deleted all data in detailed and summary tables and refill using the code from Part D
CREATE OR REPLACE PROCEDURE refresh_table_data()
LANGUAGE plpgsql
AS
$$
BEGIN
	DELETE FROM detailed_table;
	DELETE FROM summary_table;

	INSERT INTO detailed_table
	SELECT 
		p.payment_id, p.amount, ci.city, co.country,
		sale_date(p.payment_date)
	FROM payment p
	INNER JOIN customer cu
	ON p.customer_id = cu.customer_id
	INNER JOIN address a
	ON cu.address_id = a.address_id
	INNER JOIN city ci
	ON a.city_id = ci.city_id
	INNER JOIN country co
	ON ci.country_id = co.country_id;
RETURN;
END;
$$

-- testing stored procedure
SELECT * FROM detailed_table;
DELETE FROM detailed_table WHERE city = 'Ede';

CALL refresh_table_data();

SELECT * FROM summary_table;
INSERT INTO detailed_table VALUES (169963, 499.99, 'Detroit', 'United States', '2007-02-15 22:25:46.996577');