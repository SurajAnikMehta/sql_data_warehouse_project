
/*
--DDL Script: Create silver Tables
-----------------------------------------------
Script purpose :  This script creates tables in the silver schema, dropping existing tables
                  if already exist.
-----------------------------------------------
*/
USE datawarehouse;

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info(
	cst_id		int,
	cst_key		varchar(50),
	cst_firstname varchar(50),
	cst_lastname varchar(50),
	cst_marital_status varchar(50),
	cst_gndr varchar(50),
	cst_create_date date,
	dwh_create_date datetime2 default getdate()
);

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info(
	prd_id		int,
	cat_id		nvarchar(50),
	sub_key		nvarchar(50),
	prd_nm		nvarchar(50),
	prd_cost	int,
	prd_line	nvarchar(50),
	prd_start_dt date,
	prd_end_dt  date,
	dwh_create_date datetime2 default getdate()

)

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details(
	sls_ord_num	nvarchar(50),
	sls_prd_key	nvarchar(50),
	sls_cust_id	int,
	sls_order_dt date,
	sls_ship_dt	date,
	sls_due_dt	date,
	sls_sales	int,
	sls_quantity int,
	sls_price	int,
	dwh_create_date datetime2 default getdate()
)

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12(
	cid	varchar(50),
	bdate date,
	gen varchar(50),
	dwh_create_date datetime2 default getdate()
)

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101(
	cid	varchar(50),
	cntry varchar(50),
	dwh_create_date datetime2 default getdate()
)

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2(
	id			varchar(50),
	cat			varchar(50),
	subcat		varchar(50),
	maintenance varchar(50)
)
