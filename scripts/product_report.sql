/*Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue*/
---------------------------------------------------------------------------
--select * from gold.product_report;

if OBJECT_ID('gold.product_report','V') is not null
    Drop view gold.product_repot;

create view gold.product_report as 
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
with product_core as (
    Select 
        s.order_num,
        s.customer_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    
    from gold.fact_sales s
    left join gold.dim_products p on s.product_key = p.product_key
    where s.order_date is not null ),

/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
 product_aggregation as (
    Select 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        sum(sales_amount) as total_sales,
        sum(quantity) as total_quantity,
        max(order_date) as last_sale_date,
        count(distinct order_num) as total_orders,
        count(distinct customer_key) as total_customer,
        datediff(month,min(order_date),max(order_date)) as lifespan,
        Round(Avg(cast(sales_amount as float ) / nullif(quantity, 0)),1) as Avg_selling_price
    from product_core
    group by product_key, product_name, category, subcategory, cost )

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/

    select 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        case when cost < 100 then 'Below 100'
                when cost between 100 and 500 then '100-500'
                when cost between 500 and 1000 then '500-1000'
                Else 'Above 1000'
        End as cost_range,
        last_sale_date,
        DATEDIFF(month,last_sale_date,getdate()) as recency_in_months,
        total_sales,
        total_quantity,
        total_customer,
        Avg_selling_price,
        Case When total_sales > 50000 then 'High performer'
             When total_sales >= 10000 then 'Mid Range'
             Else 'low performer'
        End as product_segment,
        -- Average Order Revenue (AOR)
        case when total_orders = 0 then 0
                Else total_sales/ total_orders
        End as avg_order_value,
        -- average monthly revenu
        case when lifespan = 0 then total_sales
                else total_sales/lifespan
        End as avg_monthly_revenue
    From product_aggregation


