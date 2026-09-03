
/*


==============================================================================
Quality Checks
==============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' schema. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ============================================================================
-- Checking 'silver.crm_cust_info'
-- ============================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results


-------------------------------------------------------------------------
--BRONZE TABLE crm_cust_info - data clean 
-------------------------------------------------------------------------
--find the duplicates and null records in the table
select cst_id, count(*)
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

--Check for unwanted Spaces
--Expection : No Result
SELECT cst_firstname 
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);
--if the orignal value does not have the same value after trimming, it means there are spaces
SELECT  cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

--Data Standrization & Consistency
SELECT Distinct cst_gndr
from bronze.crm_cust_info

SELECT Distinct cst_marital_status
from bronze.crm_cust_info

-------------------------------------------------------------------------
--sliver table checking 
-------------------------------------------------------------------------
	select * from silver.crm_cust_info
	--find the duplicates and null records in the table
	select cst_id, count(*) from silver.crm_cust_info
	group by cst_id having count(*) >1 or cst_id is null

	select cst_key from silver.crm_cust_info
	where cst_key is null

	--Check for unwanted Spaces
	select cst_lastname
	from silver.crm_cust_info
	where cst_lastname != TRIM(cst_lastname) --did for all the columns


	--Data Standrization & Consistency
	select  cst_create_date  from silver.crm_cust_info
	where cst_key is null

	select distinct cst_gndr from silver.crm_cust_info;
	select distinct cst_marital_status from silver.crm_cust_info;

-------------------------------------------------------------------------
--BRONZE TABLE prd_info - data clean 
-------------------------------------------------------------------------
SELECT * FROM bronze.crm_prd_info;
--find the duplicates and null records in the table
SELECT prd_id, count(*)
from bronze.crm_prd_info
group by prd_id having count(*) > 1 or prd_id is null

--Check for unwanted Spaces
SELECT prd_key, SUBSTRING(prd_key, 1, 5) as cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) as sub_key
FROM bronze.crm_prd_info;

SELECT prd_nm
FROM bronze.crm_prd_info
where prd_nm !=TRIM(prd_nm);

--Check for null and negtative cost
SELECT prd_cost
FROM bronze.crm_prd_info
where prd_cost <0 or prd_cost is null;

--Data Standrization & Consistency
select distinct prd_line
FROM bronze.crm_prd_info

--check invalid date Orders
SELECT *,
dateadd(day,-1,lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)) AS prd_end_dt_test
FROM bronze.crm_prd_info

--SELECT *
--FROM INFORMATION_SCHEMA.COLUMNS 
--WHERE TABLE_NAME = 'crm_prd_info';

--exec sys.sp_columns crm_prd_info;

-------------------------------------------------------------------------
--silver TABLE prd_info - quality check 
-------------------------------------------------------------------------
SELECT * FROM silver.crm_prd_info

--find the duplicates and null records in the table
Select prd_id, sub_key, cat_id --count(*)
from silver.crm_prd_info
where sub_key is null
group by prd_id,sub_key, cat_id having count(*) >1 or prd_id is null

--Check for unwanted Spaces
SELECT prd_nm, prd_line 
FROM silver.crm_prd_info
where prd_line != Trim(prd_line)

--Check for null nad negtative
SELECT prd_cost FROM silver.crm_prd_info
where prd_cost <0 or prd_cost is null
--Data Standrization & Consistency
--check invalid date Orders

-------------------------------------------------------------------------
--BRONZE TABLE crm_details - data clean 
-------------------------------------------------------------------------
SELECT * FROM bronze.crm_sales_details

--find the duplicates and null records in the table
SELECT sls_prd_key, count(*)
from bronze.crm_sales_details
group by sls_prd_key having count(*) > 1 or sls_prd_key is null
--where sls_cust_id NOT IN (SELECT cust_id FROM silver.cust_info)

--Check for unwanted Spaces
SELECT sls_prd_key
from bronze.crm_sales_details
where sls_prd_key != TRIM(sls_prd_key)

--Check for null and negtative
SELECT *,
case WHEN sls_sales is null THEN sls_quantity*sls_price
	 WHEN sls_sales <= 0  THEN sls_quantity*sls_price
	 ELSE sls_sales
END sls_sales_test
from bronze.crm_sales_details
where sls_ord_num = 'SO61548'
--where sls_sales <=0 or sls_sales is null

--Data Standrization & Consistency

select * from bronze.crm_sales_details
where sls_sales != sls_price * sls_quantity or 
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales = 0 or sls_quantity = 0 or sls_price =0

SELECT 
	sls_sales,
	sls_price,
	CASE WHEN sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * ABS(sls_price)
			THEN  sls_quantity * ABS(sls_price) 
		 ELSE sls_sales
	END sls_sales_, 
	sls_quantity ,
	CASE WHEN sls_price is null or sls_price <=0 then sls_sales/sls_quantity
		 ELSE sls_price
	END sls_price_
FROM bronze.crm_sales_details
where sls_sales != sls_price * sls_quantity or 
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales = 0 or sls_quantity = 0 or sls_price =0

--check invalid date Orders
SELECT *, NULLIF(sls_order_dt,0) as order_dt
from bronze.crm_sales_details
where sls_order_dt <=0 OR sls_order_dt !=8

--check invalid date Orders
SELECT *
from bronze.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

-------------------------------------------------------------------------
--SILVER TABLE sales_details - data check 
-------------------------------------------------------------------------
--Data Standrization & Consistency

select * from silver.crm_sales_details
where sls_sales != sls_price * sls_quantity or 
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales = 0 or sls_quantity = 0 or sls_price =0

SELECT 
	sls_sales,
	sls_price,
	sls_quantity
FROM silver.crm_sales_details
where sls_sales != sls_price * sls_quantity or 
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales = 0 or sls_quantity = 0 or sls_price =0


--check invalid date Orders
SELECT *
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

-------------------------------------------------------------------------
--BRONZE TABLE erp_cust_az12 - data clean (null,duplicate,invalid date, data consistency)
-------------------------------------------------------------------------
SELECT * FROM bronze.erp_cust_az12 

SELECT
	CASE WHEN cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
		 ELSE cid
	END cid
FROM bronze.erp_cust_az12


--where cid is null or bdate is null or gen is null
--group by cid having count(*) >1  -- checked duplicate cid

SELECT  gen--data consistency
FROM silver.erp_cust_az12 GROUP BY gen
select gen,
CASE WHEN UPPER(TRIM(gen)) = 'M' or gen = 'Male' then 'Male'
	 WHEN UPPER(TRIM(gen)) = 'F' or gen = 'Female' then 'Female'
	 ELSE 'n/a'
END GENDER 
FROM bronze.erp_cust_az12 GROUP BY gen

--Identify out of range birth dates
SELECT bdate -- , case when year(bdate) < 1924 or bdate > GETDATE() THEN NULL
--					ELSE bdate
--				End as bdate
FROM silver.erp_cust_az12 
where year(bdate) < 1924 or bdate > GETDATE()

-------------------------------------------------------------------------
--BRONZE TABLE erp_loc - data clean 
-------------------------------------------------------------------------
SELECT REPLACE(cid,'-','') as cid
FROM bronze.erp_loc_a101 

--data consistency
Select cntry,	CASE 
		 WHEN UPPER(TRIM(cntry)) in ('US', 'USA') THEN 'United States'
		 WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Denmark'
		 WHEN cntry is null then 'n/a'
		 ELSE cntry
	END as cln_cntry
From bronze.erp_loc_a101

-------------------------------------------------------------------------
--BRONZE TABLE erp_px_cat_g1v2 - data clean 
-------------------------------------------------------------------------
select * from bronze.erp_px_cat_g1v2
--find the duplicates and null records in the table
select * from bronze.erp_px_cat_g1v2 where id is null or cat is null or subcat is null or maintenance is null

--Check for unwanted Spaces
select * from bronze.erp_px_cat_g1v2 
	where id != trim(id) or cat != trim(cat) or subcat != trim(subcat) or maintenance != TRIM(maintenance)


--Data Standrization & Consistency
select distinct cat, subcat, maintenance from bronze.erp_px_cat_g1v2



