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
﻿﻿-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
  cst_id,
  COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for particular cst_id = 29466; duplicates (checking how func ROW_NUMBER() is working)
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

-- Choosing all of duplicates (need a subquerry bcz clause in Where is erlier than columns is Select clause)
SELECT * FROM 
  (SELECT *,
  ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
  FROM bronze.crm_cust_info
)t WHERE flag_last != 1;

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
  CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	  WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
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
﻿Checking 'silver,crm_prd_info'
===================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results  
SELECT 
  prd_id,
  COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

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

-- Check for Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

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
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
-- WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- Check for Invalid Dates
SELECT
  sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt < 0;

SELECT
  sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

-- Check for Invalid Dates
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8;

-- Final full check
SELECT
  NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- Final full check sls_ship_dt
SELECT
  NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

-- Final full check sls_due_dt
SELECT
  NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Check for Invalid Date Orders
SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-->> Values must not be NULL, zero, or negative
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price,
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price;

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
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;

===================================================================
﻿Checking 'silver,erp_cust_az12'
===================================================================






























































