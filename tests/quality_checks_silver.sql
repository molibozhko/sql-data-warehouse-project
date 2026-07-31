/*
===================================================================
Quality Checks
===================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy, 
  and standardization across the 'silver' schemas. It includes checks for:
﻿﻿  - Null or duplicate primary keys.
﻿﻿  - Unwanted spaces in string fields.
﻿﻿  - Data standardization and consistency.
﻿﻿  - Invalid date ranges and orders.
﻿﻿  - Data consistency between related fields.
Usage Notes:
﻿  - ﻿Run these checks after data loading Silver Layer.
﻿﻿  - Investigate and resolve any discrepancies found during the checks.
===================================================================
*/

===================================================================
﻿Checking 'silver,crm_cust_info'
===================================================================
﻿﻿SELECT 
*
FROM bronze.crm_cust_info;
	
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
  cst_id,
  COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

SELECT
*
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

-- Check for particular cst_id = 29466; duplicates (checking how func ROW_NUMBER() is working)
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

SELECT
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info;

-- Choosing all of duplicates (need a subquerry bcz clause in Where is erlier than columns is Select clause)
SELECT * FROM 
  (SELECT *,
  ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
  FROM bronze.crm_cust_info
)t WHERE flag_last != 1;

-- vice versa 
SELECT * FROM 
  (SELECT *,
  ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
  FROM bronze.crm_cust_info
)t WHERE flag_last = 1;

-- Choosing unique row with cst_id = 29466
SELECT
  *
FROM (
    SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
  FROM bronze.crm_cust_info
)t WHERE flag_last = 1 AND cst_id = 29466;

-- Final subquerry
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL

-- Check for unwanted Spaces (If the original value is not equal to the same value after trimming, it means there are spaces)
-- Expectation: No Results
SELECT 
  cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key);
	
SELECT 
  cst_firstname
FROM bronze.crm_cust_info;

-- Check for unwanted Spaces 
-- Expectation: No Results
SELECT 
  cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- The same check for unwanted Spaces for cst_lastname
SELECT 
  cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data Standartization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

-- Normalize gender values to redable format
SELECT
  CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	  WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	  ELSE 'n/a'
    END cst_marital_status, -- Normalize marital status velues to readable format
  CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' -- Apply Upper() just in case mixed-case velues appear later in your column
	  WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' -- Apply TRIM() just in case spaces appear later in your column
	  ELSE 'n/a'
    END cst_gndr, -- Normalize gender values to redable format
FROM bronze.crm_cust_info

-- Final querry 
SELECT
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a'
END cst_marital_status, -- Normalize marital status velues to readable format
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a'
END cst_gndr, -- Normalize gender values to redable format
cst_create_date
FROM (
	SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t WHERE flag_last = 1; -- Select the most recent record per customer

===================================================================
-- Qality check of the Silver Table

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
  cst_id,
  COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted Spaces 
-- Expectation: No Results
SELECT 
  cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Check for unwanted Spaces 
-- Expectation: No Results
SELECT 
  cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Check for unwanted Spaces 
-- Expectation: No Results
SELECT 
  cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info

===================================================================
﻿Checking 'silver,crm_prd_info'
===================================================================
SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results  
SELECT 
  prd_id,
  COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Filters out unmatched data after applying transformation
SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info;

SELECT DISTINCT id FROM bronze.erp_px_cat_g1ve; -- We should double check this table, bcz this table could be joined to prd_info
-- As we see id FROM bronze.erp_px_cat_g1ve includs '_' instead of '-'
	
SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN -- We try to find cat_id which is not in erp_px_cat_g1ve
(SELECT DISTINCT id FROM bronze.erp_px_cat_g1ve);
-- We don't have only one cat_id which is not included in bronze.erp_px_cat_g1ve, check this cat_id in bronze.erp_px_cat_g1ve:

SELECT DISTINCT id FROM bronze.erp_px_cat_g1ve;  -- we definetly don't have this one cat_id in bronze.erp_px_cat_g1ve, that's fine

-- Filters out unmatched data after applying transformation
SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info;

SELECT sls_prd_key FROM bronze.crm_sales_details; -- As we see prd_key looks like  in bronze.crm_prd_info, but we should check:

SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN 
(SELECT  sls_prd_key FROM bronze.crm_sales_details); -- As we see a lot of prd_key from bronze.crm_prd_info which (products don't have any orders)
-- are not in bronze.crm_sales_details - we can check the exact prd_key(which will be cutted on several symbols)
SELECT sls_prd_key FROM bronze.crm_sales_details WHERE sls_prd_key LIKE 'FK-16%';
SELECT sls_prd_key FROM bronze.crm_sales_details WHERE sls_prd_key LIKE 'FK-1%';
SELECT sls_prd_key FROM bronze.crm_sales_details WHERE sls_prd_key LIKE 'FK%';

-- So we don't have such prd_key in bronze.crm_sales_detail, but
-- we still have a lot of prd_key which could be joined with sls_prd_key in bronze.crm_sales_details:
SELECT
*
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) IN 
(SELECT sls_prd_key FROM bronze.crm_sales_details);

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT 
  prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Data Standartization & Consistency
SELECT DISTINCT 
  prd_line
FROM bronze.crm_prd_info;

-- Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT 
  prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL; 

-- Check for Invalid Date Orders, end_date must be earlier than start_date
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- For complex transformations in SQL better to narrow it down to a specific exzmple and brainstorm multiple
-- solution approaches
-- Solution # 1: Switxh End Date and Start Date, If no overlapping
-- Solition # 2: Derive the End Date from the Start Date (End Date = Start Date of the Next Record), even better to substruct 1 day
-- which exclude overlapping

-- It's better to check on exzct rows with issues dates and If the choosen logic is working
SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE_HL-U509-R', 'AC-HE-HL-U509')

-- Final querry 
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) AS prd_cost,
CASE UPPER(TRIM(prd_line))
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
END AS prd_line,
CAST (prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info
ORDER BY prd_id;

IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL 
	DROP TABLE silver.crm_prd_info;
﻿CREATE TABLE silver.crm_prd_info (
	prd_id INT, 
	cat_id NVARCHAR(50), 
	prd_key NARCHAR(50), 
	prd_nm NVARCHAR(50), 
	pra_cost INT, 
	prd_line NVARCHAR(50), 
	prd_start_dt DATE, -- changing the format from DATETIME to DATE
	prd. _end_dt DATE, 
	dwh_create_date DATETIME DEFAULT GETDATE ();

===================================================================
-- Qality check of the Silver Table

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results  
SELECT 
  prd_id,
  COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT 
  prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT 
  prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL; 

-- Data Standartization & Consistency
SELECT DISTINCT 
  prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders, end_date must be earlier than start_date
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

SELECT *
FROM silver.crm_prd_info;

===================================================================
﻿Checking 'silver,crm_sales_details'
===================================================================

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  sls_order_dt,
  sls_ship_dt,
  sls_due_dt,
  sls_sales,
  sls_quantity,
  sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Expectation: No Results (we should chrck in other tables, which could be joined on these keys)
SELECT
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  sls_order_dt,
  sls_ship_dt,
  sls_due_dt,
  sls_sales,
  sls_quantity,
  sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check for Invalid Dates (checking whether we have negative valuees or not)
SELECT
  sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt < 0;

-- Check for Invalid Dates (checking whether we have zero valuees or not)
SELECT
  sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

-- Check for Invalid Dates
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

-- Checking all column of date
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
-- Dates should include not more than 8 symbols (according to that how date is presented - length of date must be 8)

-- Replacing 0 values on NULL (this func returns NULL if two given values are equal, otherwise it returns first expression)
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8;

-- Check for outliers by validating the boundaries of the date range
-- >> Also order_dates/shipping/due_date shouldn't be more than future, for example - 20500101
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > 20500101;

-- Check for outliers by validating the boundaries of the date range
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- Finding all of garbage with dates
-- >>  We should add all of checks for validating dates (we don't need a dates which length less than 8 and with other inconsistencies)
-- >>  Final full check dates
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- Checking the rest columns with dates for finding uncorrect dates
-- Final full check sls_ship_dt
SELECT
  NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

-- Checking the rest columns with dates for finding uncorrect dates
-- Final full check sls_due_dt
SELECT
  NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Check for Invalid Date Orders
-- >>  checking for broken Logic, Order Date must always be erlier than the Shipping Date or Due Date
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Should be consudered the rull - Sales = sls_quantity * sls_price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price,
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price;
-- According to what we have (negative values, zeros and nulls) - need to talk with someone from the bisness 
-- or source system and discuss, two solution:
-- data issues will be fixed direct in source system
-- data issues has to be fixed in data warehouse 

-- We choosing all of broken data and following the rules:
-- If Sales is negative, zero, or null, derive it using Quantity and Price.
-- If Price is zero, or null, calculate it using Sales and Quantity. 
-- If Price is negative, convert it to a positive value 
-- In result should be cleaned and correct data
SELECT DISTINCT
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Final querry 
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_order_dt AS varchar)AS DATE)
END AS sls_order_dt,
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_ship_dt AS varchar)AS DATE)
END AS sls_ship_dt,
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	ELSE CAST(CAST(sls_due_dt AS varchar)AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales, -- Recalculate sales if origal values is mising or incorrect
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price -- Derive price if original value is missing or incorrect 
END AS sls_price
FROM bronze.crm_sales_details;

-- Because of changing format of dates (from integer to Date) - we should check the DDL and change the format
-- of the table before inserting data in silver table
IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details ( 
  sls_ord_num NVARCHAR(50) ,
  sls_prd_key NVARCHAR(50),
  sls_cust_id INT,
  sis_order_dt DATE, -- Changing the data type from INT to Date
  sls_ship_dt DATE, -- Changing the data type from INT to Date
  s1s_due_dt DATE, -- Changing the data type from INT to Date
  sls_sales INT,
  sls_quantity INT, 
  sls_price INT
);

===================================================================
-- Qality check of the Silver Table

SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check for Invalid Date Orders	
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Between Sales, Quantity, and Price
SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price,
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price;

SELECT *
FROM silver.crm_sales_details


===================================================================
﻿Checking 'silver,erp_cust_az12'
===================================================================

SELECT * FROM bronze.erp_cust_az12;

SELECT
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12;

SELECT * FROM silver.crm_cust_info; -- we can compare two tables to understand how id from bronze.erp_cust_az12 and 
-- cst_key from bronze.erp_cust_az12 could be joined, as we see there is extra charecters in id from bronze.erp_cust_az12 

SELECT
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011000%'; -- we are looking for specific cid from bronze.erp_cust_az12 which has been shown in silver.crm_cust_info
							   -- and we find it, but with three extra characters in begining (NAS)
SELECT
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12; -- If we again check the data we can conclude than only old data have extra character and new data doesen't have it;
						   -- >>  we can delete extra NAS

SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12;

-- Expectation: we are not able to find any unmatching data btw the bronze.erp_cust_az12 and silver.crm_cust_info after transformation;
SELECT
cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info); 

-- If we change where clause - we will see al of uncorrect cid)
-- Therefore It seems that previous code is working perfectly
SELECT
cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE  cid
NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);

-- Identify Out-Of_Range Dates
-- Check for very old customers
SELECT DISTINCT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01'; -- It look likes that we have a lot of customers, that are older than 100 years

-- Check the birthdays in the future
SELECT DISTINCT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE(); -- as we see we have some dates which are invalid (birthdays in the future)
-- Solution:
-- report to the source system in order to correct it
-- leave it as it is, as a bad data
-- clean it up, by replacing bad dates with a NULL or replacing only that days which is extreme

SELECT DISTINCT
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

SELECT
CASE WHEN bdate > GETDATE() THEN NULL 
ELSE bdate
END AS bdate
FROM silver.erp_cust_az12; 

-- Data Standartization & Consistency 
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

SELECT gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;

-- Final querry
SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix present
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL 
	ELSE bdate
	END AS bdate, -- Set future birthdates to NULL
	CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen -- Normalize gender values and handle unknown cases
FROM bronze.erp_cust_az12;

===================================================================
-- Qality check of the Silver Table
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

SELECT DISTINCT gen
FROM silver.erp_cust_az12;

-- Final look
SELECT * FROM silver.erp_cust_az12;

===================================================================
﻿Checking 'silver,erp_loc_a101'
===================================================================

SELECT *
FROM bronze.erp_loc_a101;

SELECT 
cid,
cntry
FROM bronze.erp_loc_a101;

SELECT cst_key FROM silver.crm_cust_info;

SELECT
REPLACE(cid, '-', '') cid,
cntry 
FROM bronze.erp_loc_a101;

-- Checking that code is working (it should be no results)
SELECT
REPLACE(cid, '-', '') cid,
cntry 
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN 
(SELECT cst_key FROM silver.crm_cust_info);

-- Data Standartization and Consistency
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

SELECT DISTINCT 
cntry AS old_cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;

-- Final querry
SELECT
REPLACE(cid, '-', '') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry -- Normalize and Handle missing or blank country codes
FROM bronze.erp_loc_a101;

===================================================================
-- Qality check of the Silver Table

SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- Final check
SELECT * FROM silver.erp_loc_a101;

===================================================================
﻿Checking 'silver,erp_px_cat_g1v2'
===================================================================
SELECT
	id,
	cat,
	subcat,
	maintenance
FROM bronze.erp_px_cat_g1v2;

-- Check for unwanted Spaces
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

-- Check for unwanted Spaces
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Data Standartization & Consistency
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2;

-- Data Standartization & Consistency
SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2;

===================================================================
-- Qality check of the Silver Table

SELECT * FROM silver.erp_px_cat_g1v2;































































