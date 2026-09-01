
/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

create or alter PROCEDURE bronze.load_bronze AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_time_bronze datetime, @end_time_bronze datetime;
    BEGIN TRY

    set @start_time_bronze = GETDATE();

    PRINT '==============================================================';
    PRINT 'Loading CRM Table';
    PRINT '==============================================================';

    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    PRINT '>> Inserting Data Into: bronze.crm_cust_info';
    bulk insert bronze.crm_cust_info
    FROM 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH ( 
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
        );
    SET @end_time = GETDATE();
    PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) as NVARCHAR) + 'seconds';
    PRINT '--------------------';

    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    PRINT '>> Inserting Data Into: bronze.crm_prd_info';
    bulk insert bronze.crm_prd_info
    FROM 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH ( 
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
        );
    SET @end_time = GETDATE();
    PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
    PRINT '--------------------';


    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    PRINT '>> Inserting Data Into: bronze.crm_sales_details';
    bulk insert bronze.crm_sales_details
    FROM 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH ( 
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
        );
    SET @end_time = GETDATE();
    PRINT '>> load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
    PRINT '--------------------';

    PRINT '==============================================================';
    PRINT 'Loading ERP Table';
    PRINT '==============================================================';

    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;

    PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
    bulk insert bronze.erp_cust_az12
    from 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
    with (
        firstrow = 2,
        fieldterminator = ',',
        tablock
    );
    SET @end_time = GETDATE();
    PRINT '>> load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
    PRINT '--------------------';

    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
    bulk insert bronze.erp_loc_a101
    from 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
    with (
        firstrow = 2,
        fieldterminator = ',',
        tablock
    );
    SET @end_time = GETDATE();
    PRINT '>> load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
    PRINT '--------------------';

    SET @start_time = GETDATE();
    PRINT '>> TRUCATING TABLE: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
    bulk insert bronze.erp_px_cat_g1v2
    from 'C:\Users\LENOVO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
    with (
        firstrow = 2,
        fieldterminator = ',',
        tablock
    );
    SET @end_time = GETDATE();
    PRINT '>> load Duration : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'seconds';
    PRINT '--------------------';

    set @end_time_bronze = GETDATE();
    print '>> Load Duration of Bronze layer : ' + cast(datediff(second,@start_time_bronze, @end_time_bronze) as nvarchar) + 'seconds';
    PRINT '--------------------';


    END TRY
    BEGIN CATCH
    PRINT '=====================================================';
    PRINT 'ERROR OCCURED DURING THE LOADING BRONZE LAYER';
    PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
    PRINT 'ERROR MESSAGE' + CAST(ERROR_MESSAGE() AS NVARCHAR);
    PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
    PRINT '=====================================================';
    END CATCH
END;
