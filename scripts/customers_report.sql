
/*-----------------------------------------------------------
Build Customer Report 
-------------------------------------------------------------
Purpose : This reports consolidates key customer metrics and behaviour

Highlights:
	1. Gather essential fields such as names, ages and transcation details.
	2. Segments customers into categories (VIP, regular, New) and age group.
	3. Aggregate customer-level metrics:
		- Total orders placed
		- Total spend (lifetime sales value)
		- Total Quantity purchased
		- total products
		- Lifespan (in months)
	4. Calculates valuable KPIs
		- recency (months since last order )
		- Average order value (AOV)
		- average monthly spend */
Create view gold.customer_report As 

with base_query as (
SELECT 
	s.order_num,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	concat(c.first_name, ' ',c.last_name) as full_name,
	DATEDIFF(year,birthdate,GETDATE()) as age
FROM gold.fact_sales s left join gold.dim_customer c
On s.customer_key = c.customer_key 
Where order_date is not null )

, customer_aggregation As (
/*--------------------------------------------------------------
customer Aggregation : Summarize key metrics at the customer level
----------------------------------------------------------------*/
Select 
	customer_key,
	customer_number,
	full_name,
	age,
	count(distinct order_num) as total_orders,
	sum(sales_amount) as total_spend,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	Max(order_date) as last_order_date,
	DATEDIFF(month,min(order_date),max(order_date)) as lifespan
From base_query
group by customer_key, customer_number, full_name, age)


/*--------------------------------------------------------------
customer Aggregation : Summarize key metrics at the customer level
----------------------------------------------------------------*/

Select 
	customer_key,
	customer_number,
	full_name,
	age,
	Case When age < 20 then 'Under 20'
		 When age Between 20 and 29 then '20-29'
		 When age Between 30 and 39 then '30-39'
		 When age Between 40 and 49 then '40-49'
		 Else '50+'
	End age_group,
		CASE When lifespan >= 12 And total_spend > 5000 then 'VIP'
		 When lifespan >= 12 And total_spend < 5000 then 'Regular'
		 Else 'New'
	End customer_segment,
	total_orders,
	total_spend,
	total_quantity,
	total_products,
	last_order_date,
	--- recency (months since last order )
	DATEDIFF(month,last_order_date,getdate()) as recency,
	--- Average order value (AOV)
	Case when lifespan = 0 Then 0
		 Else total_spend/ lifespan 
		 End as avg_monthly_spend,
		--- average monthly spend
	Case when total_spend = 0 Then 0
		 Else total_spend / total_orders
		 End as avg_order_value,
	lifespan
From customer_aggregation

