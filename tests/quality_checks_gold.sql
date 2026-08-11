/*
=============================================================================
Quality Checks
=============================================================================
Script Purpose:
  This script performs quality checks to validate the integrity, consistency, 
  and accuracy of the Gold Layer. These checks ensure:
﻿  - ﻿Uniqueness of surrogate keys in dimension tables.
﻿  - ﻿Referential integrity between fact and dimension tables.
﻿﻿  - Validation of relationships in the data model for analytical purposes.

Usage Notes:
﻿﻿  - Run these checks after data loading Silver Layer.
﻿﻿  - Investigate and resolve any discrepancies found during the checks.
=============================================================================
*/

-- ===================================================================
﻿-- Checking 'gold.dim_customers'
-- ===================================================================
SELECT 
*
FROM silver.crm_cust_info;

-- Now we selecting columns which should be presented in the gold layer
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;

-- After Joining table, we double check if any duplicates were introduced 
SELECT cst_id, COUNT(*) FROM
	(SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		la.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
	  ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 la
	  ON ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1;

-- We have 2 sourses about gndr
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
ORDER BY 1, 2; -- We have different scenarios, the data could be mistakenly differenrt, also NULLS has appeared bcz of join

-- When the data is different from 2 sourses, we have to ask experts about it - which soursce the master for this values?
-- Let's say that In this case the Master Source of Customer Data is CRM
SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
ORDER BY 1, 2;

-- Final querry 
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen,
	ci.cst_create_date,
	ca.bdate,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;

-- Rename columns to friendly, meaninful names
-- General Principles
-- >> Naming Conventions: Use snake_case, with lowercase letters and underscores (_) to separate words.
-- >> Language: Use English for all names
-- >> Avoid Reserved Words: Do not use SQL reserved words as object names
SELECT 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ci.cst_create_date AS create_date,
	ca.bdate AS birthdate,
	la.cntry AS country
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;

-- Sort the columns into logical groups to improve readability and then adding Surrogate key
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;

-- Dimension vs Fact? - It's Dimension Table.

-- Create the object, create a view
CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;

-- Quality Check of the Gold Table
SELECT * FROM gold.dim_customers;

SELECT distinct gender FROM gold.dim_customers;

-- ===================================================================
﻿-- Checking 'gold.dim_products'
-- ===================================================================

SELECT 
  pn.prd_id,
  pn.cat_id,
  pn.prd_key,
  pn.prd_nm,
  pn.prd_cost,
  pn.prd_line,
  pn.prd_start_dt,
  pn.prd_end_dt
FROM silver.crm_prd_info pn;

SELECT * FROM silver.erp_px_cat_g1v2;

-- We should filter out historical data and then join other table
-- If End Date IS NULL - It is Current Info of the Product
SELECT 
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL; -- Filter out all historical data

-- Check of uniqueness of prd_key after join
SELECT prd_key, COUNT(*) FROM (
SELECT  
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL
)t GROUP BY prd_key
HAVING COUNT(*) > 1;

-- Sort the columns into logical groups to improve readability
SELECT 
	pn.prd_id,
	pn.prd_key,
	pn.prd_nm,
	pn.cat_id,
	pc.cat,
	pc.subcat,
	pc.maintenance,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL;

-- Rename columns to friendly, meaningful names and after that add unique identifier
SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, 
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL; -- Filter out all historical data

-- This is dimension table
-- Creation view
CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, 
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL;

SELECT * FROM gold.dim_products

-- ===================================================================
﻿-- Checking 'gold.fact_sales'
-- ===================================================================

SELECT
  sd.sls_ord_num,
  sd.sls_prd_key,
  sd.sls_cust_id,
  sd.sls_order_dt,
  sd.sls_ship_dt,
  sd.sls_due_dt,
  sd.sls_sales,
  sd.sls_quantity,
  sd.sls_price
FROM silver.crm_sales_details sd;

-- Because this table keys, dates, measures - It's fact table;
-- Building Fact: use the dimension's surrogate keys instead of IDs to easily connect facts with dimensions
-- We have to put the surrogate keys from the dimensions in the facts
SELECT
  sd.sls_ord_num,
  pr.product_key, -- we don't need the original product_key (sd.sls_prd_key) from the source system, we need the
  cu.customer_key,-- surrogate key, that we have generated from the data warehouse
  sd.sls_order_dt,
  sd.sls_ship_dt,
  sd.sls_due_dt,
  sd.sls_sales,
  sd.sls_quantity,
  sd.sls_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;
-- Now we have two dimension keys, we can connect fact tables to dimensions 

-- Rename columns to friendly
SELECT
  sd.sls_ord_num AS order_number,
  pr.product_key, 
  cu.customer_key,
  sd.sls_order_dt AS order_date,
  sd.sls_ship_dt AS shipping_date,
  sd.sls_due_dt AS due_date,
  sd.sls_sales AS sales_amount,
  sd.sls_quantity AS quantity,
  sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;

CREATE VIEW gold.fact_sales AS
SELECT
  sd.sls_ord_num AS order_number,
  pr.product_key, 
  cu.customer_key,
  sd.sls_order_dt AS order_date,
  sd.sls_ship_dt AS shipping_date,
  sd.sls_due_dt AS due_date,
  sd.sls_sales AS sales_amount,
  sd.sls_quantity AS quantity,
  sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;

-- Quality Check of the Gold Table
SELECT * FROM gold.fact_sales;

-- Fact Check:
-- Check all dimension tables successfully join to the fact table
-- Foreign Key Integrity (Dimensions)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
  ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL;


SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
  ON c.customer_key = f.customer_key
LEFT JOIN  gold.dim_products p
  ON p.product_key = f.product_key
WHERE c.customer_key IS NULL;



























