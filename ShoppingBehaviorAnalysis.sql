USE                       grocerydata;

-- How many store shopping trips are recorded in your database?
# 7596145
SELECT COUNT(*) FROM trip;
SELECT COUNT(TC_id) FROM trip;

-- How many households appear in your database?
# 39577
SELECT COUNT(DISTINCT hh_id) FROM household;

-- How many stores of different retailers appear in our data base?
# 863 different retailers
SELECT COUNT(DISTINCT TC_retailer_code) FROM trip;

# 26,406 stores
SELECT SUM(retail_num) FROM (SELECT TC_retailer_code, COUNT(DISTINCT TC_retailer_code_store_code) AS retail_num
FROM trip WHERE TC_retailer_code_store_code != "0"
GROUP BY TC_retailer_code) AS groupA;

-- How many different products are recorded?
# 4,231,283
SELECT COUNT(DISTINCT prod_id) FROM product;

-- How many products per category and products per module?
# products per category: 118 
SELECT group_at_prod_id, COUNT(DISTINCT prod_id) AS num_per_category 
FROM product 
WHERE group_at_prod_id IS NOT NULL 
GROUP BY group_at_prod_id; 

# another way using temporary table
DROP TABLE IF EXISTS prodct_by_group;
CREATE TEMPORARY TABLE prodct_by_group
SELECT s.group_at_prod_id, COUNT(s.prod_id) 
FROM (
	SELECT DISTINCT prod_id, group_at_prod_id 
    FROM product
    ) AS s 
GROUP BY s.group_at_prod_id;
SELECT * FROM prodct_by_group;

# products per module: 1,224
SELECT module_at_prod_id, COUNT(DISTINCT prod_id) AS num_by_module 
FROM product 
WHERE module_at_prod_id IS NOT NULL 
GROUP BY module_at_prod_id;

# another way using temporary table
DROP TABLE IF EXISTS prodct_by_module;
CREATE TEMPORARY TABLE prodct_by_module
SELECT s.module_at_prod_id, COUNT(s.prod_id) 
FROM (
	SELECT DISTINCT prod_id, module_at_prod_id 
    FROM product
    ) AS s 
GROUP BY s.module_at_prod_id
ORDER BY s.module_at_prod_id;
SELECT * FROM prodct_by_module;

-- Plot the distribution of products and modules per department
SELECT department_at_prod_id, COUNT(DISTINCT prod_id) AS num_by_dept
FROM product WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

SELECT department_at_prod_id, COUNT(DISTINCT module_at_prod_id) AS num_mod_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

-- Total transactions and transactions realized under some kind of promotion.
	# 1. total transactions from table Trips: 7,596,145
	# 2. total transactions from table Purchases: 5,651,255
	# 3. transactions realized under some kind of promotion: 874,873
SELECT COUNT(DISTINCT(TC_id)) FROM trip;
SELECT COUNT(DISTINCT(TC_id)) FROM purchase;
SELECT COUNT(DISTINCT(TC_id)) FROM purchase WHERE coupon_value_at_TC_prod_id != "0";

-- How many households do not shop at least once on a 3 month periods.
# 48 
DROP TABLE IF EXISTS hh_month;
CREATE TABLE hh_month
	SELECT DISTINCT(date_format(TC_date,'%Y-%m-%d')) AS date, hh_id  
    FROM trip 
    ORDER BY hh_id;
SELECT * FROM hh_month;

ALTER TABLE hh_month
ADD COLUMN start_time DATETIME;

SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET start_time = '2003-12-27 00:00:00';
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE hh_month
ADD COLUMN end_time DATETIME;

SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET end_time = '2004-12-26 00:00:00';
SET SQL_SAFE_UPDATES = 1;

WITH t1 AS
(SELECT DISTINCT hh_id, (date_format(DATE,'%Y-%m-%d')) AS hh_date
FROM(
	SELECT hh_id,date FROM hh_month
	UNION 
	SELECT DISTINCT hh_id, start_time FROM hh_month
	UNION 
	SELECT DISTINCT hh_id, end_time FROM hh_month) AS t
    ORDER BY hh_id),
t2 AS
(SELECT *, ROW_NUMBER() OVER (ORDER BY hh_id) AS ID FROM t1),
t3 AS
(SELECT hh_id, hh_date, ID, 1 + ID AS ID_2 FROM t2 ORDER BY hh_id)
SELECT DISTINCT (t3.hh_id), t3.hh_date AS date_of_puchase, t2.hh_date AS date_of_next_puchase, datediff(t2.hh_date,t3.hh_date) AS TIME_WINDOW_SIZE 
FROM t3 
LEFT JOIN  t2
ON t2.ID = t3.ID_2
WHERE datediff(t2.hh_date, t3.hh_date) > 90;



-- Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average) on single retailer? 
	-- households shop at least once a month
	# 35,962

SELECT DISTINCT(hh_id), num_purchase 
FROM(
	SELECT hh_id, COUNT(DISTINCT (MONTH(TC_date))) AS num_purchase
	FROM trip
	GROUP BY hh_id
	ORDER BY hh_id) AS t
WHERE num_purchase = 12;

	-- grocery expenditure (on average) on single retailer
	# 124
DROP TABLE IF EXISTS single_loyalty;
CREATE TABLE single_loyalty
SELECT hh_ID, TC_retailer_code
FROM (
	SELECT hh_ID,TC_retailer_code, COUNT(purchase_month) AS count_month
	FROM (
		SELECT hh_id,TC_retailer_code, purchase_month
		FROM (
			SELECT A.*, B.spend_monthly_average
			FROM (
				SELECT hh_id, TC_retailer_code, MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS spend_monthly_average_by_retailer
				FROM trip
				GROUP BY hh_id, TC_retailer_code, purchase_month
				ORDER BY hh_id, purchase_month) AS A
			LEFT JOIN (
				SELECT hh_id, MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS spend_monthly_average
				FROM trip
				GROUP BY hh_id, purchase_month
				ORDER BY hh_id, purchase_month) AS B
			ON A.hh_id = B.hh_id AND A.purchase_month = B.purchase_month) AS C
	WHERE spend_monthly_average_by_retailer > 0.8*spend_monthly_average) AS D
	GROUP BY hh_id, TC_retailer_code) AS E
WHERE count_month = 12;
SELECT * FROM single_loyalty;

-- Demographics Analysis

# details of single loyalty
SELECT household.* 
FROM single_loyalty
LEFT JOIN household
ON single_loyalty.hh_id = household.hh_id;

# distribution between race
SELECT hh_race AS race, COUNT(hh_id) 
FROM (
	SELECT H.*  
    FROM single_loyalty
	LEFT JOIN household AS H
	ON single_loyalty.hh_id = H.hh_id) AS T
GROUP BY hh_race;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx, COUNT(hh_id) 
FROM (
	SELECT household.*  
    FROM single_loyalty
	LEFT JOIN household
	ON single_loyalty.hh_id = household.hh_id) AS T
GROUP BY hh_is_latinx;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) 
FROM (
	SELECT household.*  
    FROM single_loyalty
	LEFT JOIN household
	ON single_loyalty.hh_id = household.hh_id) AS T
GROUP BY hh_size;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM (
	SELECT household.*  
    FROM single_loyalty
	LEFT JOIN household
	ON single_loyalty.hh_id = household.hh_id) AS T
GROUP BY hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM (
	SELECT household.*  
	FROM single_loyalty
	LEFT JOIN household
	ON single_loyalty.hh_id = household.hh_id) AS T
GROUP BY hh_residence_type;

# household by states
SELECT hh_state AS State, COUNT(*) AS number
FROM (
	SELECT hh_state 
	FROM single_loyalty
	LEFT JOIN household
	ON single_loyalty.hh_id = household.hh_id) AS T
GROUP BY hh_state;


-- What is the retailer that has more loyalists?
SELECT TC_retailer_code,COUNT(hh_id) AS number
FROM single_loyalty
GROUP BY TC_retailer_code
ORDER BY COUNT(hh_id) DESC;        


-- Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average) among 2 retailers?
# 316
DROP TABLE IF EXISTS Loyalism;
CREATE TABLE Loyalism
SELECT *, ROW_NUMBER() OVER (PARTITION BY hh_id, purchase_month ORDER BY spend_monthly_average_by_retailer DESC) AS ID
FROM (
	SELECT A.*, B.spend_monthly_average
	FROM (
		SELECT hh_id, TC_retailer_code, MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS spend_monthly_average_by_retailer
		FROM trip
		GROUP BY hh_id, TC_retailer_code, purchase_month
		ORDER BY hh_id,purchase_month) AS A
		LEFT JOIN (
			SELECT hh_id, MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS spend_monthly_average
			FROM trip
			GROUP BY hh_id, purchase_month
			ORDER BY hh_id, purchase_month) AS B
		ON A.hh_id = B.hh_id AND A.purchase_month = B.purchase_month) AS C;
SELECT * FROM Loyalism;



DROP TABLE IF EXISTS Loyalism_TOP_2_CONCAT;
CREATE TABLE Loyalism_TOP_2_CONCAT WITH 
t1 AS (
	SELECT * 
	FROM Loyalism 
	WHERE ID IN (1, 2)),
t2 AS (
	SELECT *, ROW_NUMBER() OVER (PARTITION BY hh_id) AS rank_1
	FROM t1),
t3 AS (
	SELECT hh_id, TC_retailer_code, spend_monthly_average_by_retailer, rank_1-1 AS rank_2 
    FROM t2)
SELECT t3.hh_id, t2.purchase_month, t2.TC_retailer_code AS retailer_1, t3.TC_retailer_code AS retailer_2, t2.spend_monthly_average_by_retailer AS retailerz_spend_1, t3.spend_monthly_average_by_retailer AS retailerz_spend_2, t2.spend_monthly_average
FROM t2
LEFT JOIN t3
ON t2.rank_1 = t3.rank_2 AND t2.hh_id= t3.hh_id;
SELECT * FROM  Loyalism_TOP_2_CONCAT;

DROP TABLE IF EXISTS Loyalism_TOP_2_ODD;
CREATE TABLE  Loyalism_TOP_2_ODD
SELECT * 
FROM (
	SELECT *, ROW_NUMBER() OVER() AS rownumber 
	FROM Loyalism_TOP_2_CONCAT) tb1
WHERE tb1.rownumber % 2 = 1;
SELECT * FROM  Loyalism_TOP_2_ODD;

DROP TABLE IF EXISTS Loyalism_TOP_2_main;
CREATE TABLE  Loyalism_TOP_2_main
SELECT * 
FROM Loyalism_TOP_2_ODD 
WHERE retailerz_spend_1 + retailerz_spend_2 > 0.8*spend_monthly_average;
SELECT * FROM  Loyalism_TOP_2_main;

DROP TABLE IF EXISTS Loyalism_TOP_2_household;
CREATE TABLE  Loyalism_TOP_2_household
SELECT *
FROM ((
	SELECT hh_id, purchase_month, retailer_1 AS retailer, retailerz_spend_1 AS retailer_spend, spend_monthly_average
	FROM Loyalism_TOP_2_main) 
	UNION
	(SELECT hh_id, purchase_month,retailer_2 AS retailer,retailerz_spend_2 AS retailer_spend, spend_monthly_average
	FROM Loyalism_TOP_2_main)) AS A
ORDER BY  hh_id, purchase_month;
SELECT * FROM  Loyalism_TOP_2_household;

# list of household meet the requirement of Loyalism of 2 retailers.
# 198
DROP TABLE IF EXISTS Loyalism_TOP_2_household_list;
CREATE TABLE  Loyalism_TOP_2_household_list
SELECT DISTINCT(A.hh_id)
FROM (
	SELECT hh_id
	FROM (
		SELECT hh_id, COUNT(DISTINCT(purchase_month)) AS count_month
		FROM Loyalism_TOP_2_household
		GROUP BY hh_id) AS T_1
	WHERE count_month=12) AS A
LEFT JOIN (
	SELECT hh_id
	FROM (
		SELECT hh_id, COUNT(DISTINCT(retailer)) AS count_retailer
		FROM Loyalism_TOP_2_household
		GROUP BY hh_id) AS T_2
	WHERE count_retailer=2) AS B
ON A.hh_id=B.hh_id;
SELECT * FROM  Loyalism_TOP_2_household_list;

DROP TABLE IF EXISTS Loyalism_single_household_list;
CREATE TABLE  Loyalism_single_household_list
SELECT hh_ID
FROM (
	SELECT hh_ID, TC_retailer_code, COUNT(purchase_month) AS count_month
	FROM (
		SELECT hh_id,TC_retailer_code,purchase_month
		FROM (
			SELECT A.*,B.spend_monthly_average
			FROM (
				SELECT hh_id,TC_retailer_code, (MONTH(TC_date)) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
				FROM trip
				GROUP BY hh_id,TC_retailer_code,purchase_month
				ORDER BY hh_id,purchase_month) AS A
				LEFT JOIN (
					SELECT hh_id,(MONTH(TC_date)) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
					FROM trip
					GROUP BY hh_id,purchase_month
					ORDER BY hh_id,purchase_month) AS B
				ON A.hh_id = B.hh_id AND A.purchase_month = B.purchase_month) AS C
		WHERE spend_monthly_retailer >= 0.8 * spend_monthly_average) AS D
	GROUP BY hh_id, TC_retailer_code) AS E
WHERE count_month=12;
SELECT * FROM  Loyalism_single_household_list;

# final list
DROP TABLE IF EXISTS Loyalism_TOP_2_household_list_final;
CREATE TABLE Loyalism_TOP_2_household_list_final
SELECT DISTINCT(hh_id)
FROM ( 
	SELECT * FROM Loyalism_single_household_list
	UNION
	SELECT * FROM Loyalism_TOP_2_household_list) AS A;
SELECT * FROM Loyalism_TOP_2_household_list_final;

#detailed information
SELECT Loyalism_TOP_2_household.*
FROM  Loyalism_TOP_2_household_list_final
LEFT JOIN Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id;

# detailed information about Top 2 loyalism
SELECT household.*
FROM  Loyalism_TOP_2_household_list_final
LEFT JOIN household
ON household.hh_id = Loyalism_TOP_2_household_list_final.hh_id;

-- Are their demographics remarkably different? Are these people richer? Poorer?

# distribution between race
SELECT hh_race AS race,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_race
ORDER BY  number DESC;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx,COUNT(hh_id)  AS number
FROM (
	SELECT household.*
	FROM  Loyalism_TOP_2_household_list_final
	LEFT JOIN household
	ON household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_is_latinx
ORDER BY number;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) AS number
FROM (
	SELECT household.*
	FROM  Loyalism_TOP_2_household_list_final
	LEFT JOIN household
	ON household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_size
ORDER BY number DESC;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM
(SELECT household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
household
ON household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM
(SELECT household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
household
ON household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_residence_type;

-- The retailers with more loyalists?
SELECT retailer,COUNT(DISTINCT(hh_id))  AS number
FROM
(SELECT Loyalism_TOP_2_household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY retailer
ORDER BY number DESC;

-- Where do they live? Plot the distribution by state.
SELECT hh_state AS State, COUNT(*) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_state;

