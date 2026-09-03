/*
Store procedure : Load Silver Layer (Bronze -> silver)
--------------------------------------------------------------
Script Purpose: This store procedure perform ETL process to populate the silver
                Schema table form Bronze schema.
       Action Performed:
              - Truncate Silver Tables
              - Performed Tranform and cleansed data from Bronze into silver tables.
Parameters: None

Usage Example:
      Exec silver.load_silver
---------------------------------------------------------------
*/

CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
	DECLARE @start_time datetime, @end_time datetime, @prod_start_time datetime, @prod_end_time datetime  
	BEGIN TRY

	Set @prod_start_time = GETDATE();

    PRINT '==============================================================';
    PRINT 'Loading CRM Table';
    PRINT '==============================================================';

	Set @start_time = GETDATE();

    PRINT '>> TRUCATING TABLE: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    PRINT '>> Inserting Data Into: silver.crm_cust_info';
	insert into silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
	)	
	SELECT 
	cst_id,
	cst_key,
	Trim(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE WHEN Upper(Trim(cst_marital_status)) = 'M' then 'Married'
		 WHEN Upper(Trim(cst_marital_status)) = 'S' then 'Single'
		 Else 'n/a' 
	END cst_marital_status, --Normanlize marital status values to readable format
	CASE WHEN Upper(Trim(cst_gndr)) = 'M' then 'Male'
		 WHEN Upper(Trim(cst_gndr)) = 'F' then 'Female'
		 Else 'n/a' 
	END cst_gndr,--Normanlize gender values to readable format
	cst_create_date 
	from (
		select *,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		from bronze.crm_cust_info
		where cst_id is not null
		) t 
	WHERE flag_last = 1;--select the most recent record per customer

	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    PRINT '>> Inserting Data Into: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info (
		prd_id,
		cat_id,
		sub_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)

	SELECT 
		prd_id int,
		Replace(SUBSTRING(prd_key, 1, 5),'-','_') as cat_id,
		SUBSTRING(prd_key, 7, LEN(prd_key)) as sub_key,
		prd_nm ,
		isnull(prd_cost,0) as prd_cost, --coalesec
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
		END as prd_line ,
		prd_start_dt ,
		dateadd(day,-1,
			lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)
		) AS prd_end_dt
	from bronze.crm_prd_info;

	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    PRINT '>> Inserting Data Into: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details (
		sls_ord_num	,
		sls_prd_key	,
		sls_cust_id	,
		sls_order_dt ,
		sls_ship_dt	,
		sls_due_dt	,
		sls_sales	,
		sls_quantity ,
		sls_price
	)
	SELECT
		sls_ord_num	,
		sls_prd_key	,
		sls_cust_id	,
		CASE WHEN sls_order_dt = 0 or len(sls_order_dt) != 8 then null
			 ELSE CAST(CAST(sls_order_dt as varchar) as date)
		END sls_order_dt,
		CASE WHEN sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
			 ELSE CAST(CAST(sls_ship_dt as varchar) as date)
		END sls_ship_dt,
		CASE WHEN sls_due_dt = 0 or len(sls_due_dt) != 8 then null
			 ELSE CAST(CAST(sls_due_dt as varchar) as date)
		END sls_due_dt,
		CASE WHEN sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * ABS(sls_price)
				THEN  sls_quantity * ABS(sls_price) 
			 ELSE sls_sales
		END sls_sales, 
		sls_quantity ,
		CASE WHEN sls_price is null or sls_price <=0 then sls_sales/sls_quantity
			 ELSE sls_price
		END sls_price
	FROM bronze.crm_sales_details;
	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
    PRINT '==============================================================';
    PRINT 'Loading ERP Table';
    PRINT '==============================================================';

    PRINT '>> TRUCATING TABLE: silver.crm_cust_info';
    TRUNCATE TABLE silver.erp_cust_az12;

    PRINT '>> Inserting Data Into: silver.crm_cust_info';
	INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
	)
	SELECT
		CASE
			WHEN cid like 'NAS%' then SUBSTRING(cid,4,len(cid)) --Remove NAS prefix if present
			ELSE cid
		END cid,
		case 
			when bdate > GETDATE() THEN NULL 
			ELSE bdate
		End as bdate, -- Set Future birthdate is Null
		CASE 
			WHEN UPPER(TRIM(gen)) in ('M' , 'Male') then 'Male'
			WHEN UPPER(TRIM(gen)) in ('F' , 'Female') then 'Female'
			ELSE 'n/a'
		END gen --Normalize gender values and handle unkown cases
	FROM bronze.erp_cust_az12

	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    PRINT '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
	)
	SELECT 
		Replace(cid,'-','') as cid,
		CASE 
			 WHEN UPPER(TRIM(cntry)) in ('US', 'USA') THEN 'United States'
			 WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
			 WHEN Trim(cntry) = '' or cntry is null then 'n/a'
			 ELSE Trim(cntry)
		END AS cntry --Normalize and Handle missing or blank country code
	from bronze.erp_loc_a101
 
	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2 (
		id,
		cat,
		subcat,
		maintenance
	)
	select 
		id,
		cat,
		subcat,
		maintenance
	from bronze.erp_px_cat_g1v2
	SET @end_time = GETDATE();
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@start_time, @end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	Set @prod_end_time = GETDATE();
	PRINT '----------------------------------------------------'
	PRINT ' DATA LOADING COMPLETED :'
	PRINT '>> Load Time : ' + CAST(DATEDIFF(SECOND,@prod_start_time, @prod_end_time) as Nvarchar) + 'seconds'
	PRINT '----------------------------------------------------'

	SET @start_time = GETDATE();
	END TRY
	BEGIN CATCH
	PRINT '======================================================'
	PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE()
	PRINT 'ERROR MESSAGE : ' + CAST(ERROR_MESSAGE() AS NVARCHAR)
	PRINT 'ERROR MESSAGE : ' + CAST(ERROR_STATE() AS NVARCHAR)
	PRINT '======================================================'
	END CATCH
END

