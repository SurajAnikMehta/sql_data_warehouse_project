
/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- ============================================================================
-- Create Dimension: gold.dim_customers
-- ============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;

CREATE VIEW gold.dim_customer AS
	select 
		ROW_NUMBER() over(order by cst_id) as customer_key,
		cci.cst_id AS customer_id,
		cci.cst_key AS customer_number,
		cci.cst_firstname AS first_name,
		cci.cst_lastname AS last_name,
		ela.cntry AS country,
		CASE WHEN cci.cst_gndr != 'n/a' THEN cci.cst_gndr --CRM is the Master for Gender info
			 ELSE COALESCE(eca.gen, 'n/a')
		END as gender,	
		cci.cst_marital_status AS marital_status,
		eca.bdate AS birthdate,
		cci.cst_create_date AS create_date
	from silver.crm_cust_info cci
	left join silver.erp_cust_az12 eca
	on	cci.cst_key = eca.cid
	left join silver.erp_loc_a101 ela
	on  cci.cst_key = ela.cid

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;

CREATE or alter VIEW gold.dim_products AS
	select 
		ROW_NUMBER() over (order by cpi.prd_start_dt, cpi.sub_key) as product_key,
		cpi.prd_id  AS product_id,
		cpi.sub_key AS product_number,
		cpi.prd_nm AS product_name,
		cpi.cat_id AS category_id,
		epc.cat AS category,
		epc.subcat subcategory,
		epc.maintenance,
		cpi.prd_cost AS cost,
		cpi.prd_line AS prduct_line,
		cpi.prd_start_dt AS start_date
	from silver.crm_prd_info cpi
	left join silver.erp_px_cat_g1v2 epc
	on	 cpi.cat_id = epc.id
	where prd_end_dt is null  --Filter out all the Historical data

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;

create or alter view gold.fact_sales As
	select 
		sd.sls_ord_num  AS order_num,
		dp.product_key,
		dc.customer_key,
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS ship_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price
	from silver.crm_sales_details sd
	left join gold.dim_products dp
	on	 sd.sls_prd_key = dp.product_number
	left join gold.dim_customer dc
	on	 sd.sls_cust_id = dc.customer_id 

