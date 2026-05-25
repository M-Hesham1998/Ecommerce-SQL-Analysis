select * from customers_dataset 
select * from products_dataset
select * from order_items_dataset
select * from orders_dataset
select * from sellers_dataset
select * from order_payments_dataset
select * from order_reviews_dataset
select * from product_category_name_translation 

-------------------- Views --------------------

select * from RFM_View order by Total_Score desc

select * from Summary_Table

select * from MAC order by Order_Month asc

select * from Retention_Customers order by Order_Month 

select * from Cohort_analysis order by Cohort_index 

-------------------- Explore Data --------------------

select max(order_purchase_timestamp) as Last_order from orders_dataset
select min(order_purchase_timestamp) as Frist_order from orders_dataset


select product_category_name from products_dataset where product_category_name is Null  -- 610 Null 


select * from order_items_dataset 

select max(price) Max_price from order_items_dataset -- 6735
select min(price) Min_price from order_items_dataset -- 0.850

select max(freight_value) Max_F_Value from order_items_dataset -- 406.67
select min(freight_value) Min_F_Value from order_items_dataset -- 0

--------------------— Clean data --------------------

/*
EXEC sp_rename 
'product_category_name_translation.product_category_name',
'Brazilian_Name',
'COLUMN';
										 -- change the columns name for table product_category_name_translation
EXEC sp_rename 
'product_category_name_translation.product_category_name_english',
'Category',
'COLUMN';


delete from product_category_name_translation
where Brazilian_Name = 'product_category_name'       ------ Change frist row in product_category_name_translation


SELECT DISTINCT product_category_name
FROM products_dataset
WHERE product_category_name NOT IN (             -- There is two Categories didn't have translate in (product_category_name_translation)
    SELECT Brazilian_Name
    FROM product_category_name_translation
);

INSERT INTO product_category_name_translation
VALUES
('pc_gamer', 'pc_gamer'),                            -- Inser Translate to this Categories
('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_portable_appliances');
*/
--------------------— KPIs Sales Analysis --------------------

select	round(sum(price),3) AS Total_revenue ,    -- Total revenue

		round(AVG(price),2)  AS Average_Price ,  -- Avg revenue

		round((SUM(price) / COUNT(DISTINCT order_id)),2) AS Average_Order_Value , -- AOV

		count(distinct(order_id)) AS Total_Orders , -- Total Orders

		(select Count(distinct(product_id)) from products_dataset) AS Total_Products , -- Total_products
		
		(select count(distinct(customer_unique_id)) from customers_dataset) AS Total_Customers  , -- Total Customers

		(select count(distinct(seller_id)) from sellers_dataset) AS Total_seller ,

		(select AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) from orders_dataset  where order_delivered_customer_date is not null) AS Average_Delivery_Days  , -- AVG Delivery Days

		(select cast(count(case when order_status = 'delivered' then 1 end) * 100.0 / count(*) as decimal (4,2)) from orders_dataset) AS Percentage_Delivered_Orders , -- Delivered Orders %

		(select cast(count(case when order_status = 'canceled' then 1 end) * 100.0 / count(*) as decimal (4,2)) from orders_dataset) AS Percentage_Canceled_Orders  -- Canceled Orders %


from order_items_dataset

--------------------—--------------------—--------------------—--------------------—--------------------—

select distinct(order_status) , count(*) as Total_status from orders_dataset group by order_status  -- Total Oreder Status

--------------------—--------------------—--------------------—--------------------—--------------------—

go 

with cte as (

select  customer_unique_id ,
		count(distinct o.order_id) as Total_Orders

from customers_dataset c

join orders_dataset o
on o.customer_id = c.customer_id

group by customer_unique_id							-- Overall Returning Customers Rate 

)

select 	count( case when Total_Orders > 1 then 1 end ) as Repeat_Customr ,
		count(*) All_Customers ,
		( count(
			case
				when Total_Orders > 1 then 1 
			end	
				) * 100.0
		/

		count(*)
		) as Repeat_Purchase_Rate

from cte 


--------------------— Monthly Sales Trend --------------------—

select	DATEFROMPARTS(YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp),1) AS Date,
		sum(price) as Total_Revenue

from orders_dataset as od

join order_items_dataset as oi
on od.order_id = oi.order_id 

group by YEAR(order_purchase_timestamp) , 
		MONTH(order_purchase_timestamp)

order by Date asc

--------------------— Revenue by Day of Week --------------------—

select	DATENAME(WEEKDAY , order_purchase_timestamp) as Weekday,
		sum(price) as Revenue_By_Day

from orders_dataset as od

join order_items_dataset as oi
on od.order_id = oi.order_id 

group by DATENAME(WEEKDAY , order_purchase_timestamp)

order by Revenue_By_Day desc

--------------------— Revenue by Day of Month --------------------—

select	DAY(order_purchase_timestamp) as Day_Of_Month,
		sum(price) as Revenue_By_Day

from orders_dataset as od

join order_items_dataset as oi
on od.order_id = oi.order_id 

group by DAY(order_purchase_timestamp)

order by Revenue_By_Day desc

--------------------— Top Categories by Revenue --------------------—

select Category ,
		sum(price) as Total_Sales

from products_dataset pd

join product_category_name_translation as T
ON T.Brazilian_Name = pd.product_category_name

join order_items_dataset o
on pd.product_id = o.product_id

group by category

order by Total_Sales desc

--------------------— Top Cities by Revenue Performance --------------------—

select	top 10 customer_city ,
		SUM(price) as Revenue

from customers_dataset C

join orders_dataset O
on O.customer_id = C.customer_id

join order_items_dataset OI
on OI.order_id = O.order_id

where order_status = 'delivered'

group by customer_city

order by Revenue desc

--------------------— Top Selling Products by Category --------------------—

go

with count_Sales as (

select category ,pd.product_id , count(oi.order_id) Count_Sales

from products_dataset pd
join order_items_dataset oi
on pd.product_id = oi.product_id

join product_category_name_translation pt
on pt.Brazilian_Name = pd.product_category_name

group by pd.product_id ,category

)

select * ,
		dense_rank() over(partition by category order by count_sales desc) Rank

from count_Sales

--------------------— Top Sellers by Revenue --------------------—

select s.seller_id , sum(price) Total_Sales_for_seller

from sellers_dataset s

join order_items_dataset o
on o.seller_id = s.seller_id

group by s.seller_id

order by Total_Sales_for_seller desc

--------------------— Top Payment Methods --------------------—

select payment_type , count(*) Usage_count

from order_payments_dataset p

join order_items_dataset o
on p.order_id = o.order_id

group by payment_type

order by Usage_count desc

--------------------— Top Customers by Revenue --------------------—

select customer_unique_id , sum(price) Total_sales

from customers_dataset C

join orders_dataset O
on O.customer_id = C.customer_id

join order_items_dataset OI
on OI.order_id = O.order_id

group by customer_unique_id 

order by Total_sales desc

--------------------— Repeat Customers --------------------—

select distinct(customer_unique_id) , count(distinct(oi.order_id)) Total_Orders

from customers_dataset c

join orders_dataset o
on o.customer_id = c.customer_id

join order_items_dataset oi
on oi.order_id = o.order_id

group by customer_unique_id

having count(distinct(oi.order_id)) > 1

--------------------— Top Customers by Number of Orders --------------------—

select distinct(customer_unique_id) , count(distinct(oi.order_id)) Total_Orders

from customers_dataset c

join orders_dataset o
on o.customer_id = c.customer_id

join order_items_dataset oi
on oi.order_id = o.order_id

group by customer_unique_id

order by Total_Orders desc






--------------------—--------------------— Customer Summary Table --------------------—--------------------—      

go

create or alter View Summary_Table as        -- Create View for Cusomers

with Customer_Summary as (
select	customer_unique_id ,
		sum(price) Total_Spending ,
		count(distinct(oi.order_id)) Total_Order ,
		sum(price) / count(distinct(oi.order_id)) as Avg_Order ,
		min(cast(order_purchase_timestamp as date)) as First_Order_date ,
		max(cast(order_purchase_timestamp as date)) as Last_Order_date 

from customers_dataset c

join orders_dataset o
on o.customer_id = c.customer_id

join order_items_dataset oi
on oi.order_id = o.order_id

group by customer_unique_id

)

select	* ,
		DATEDIFF(day , First_Order_date , Last_Order_date) as Customer_Lifetime_Days ,
		dense_rank() over(order by total_order desc) as Customer_Rank_By_Order

from Customer_Summary

go

							-- The End Of View 

select * from Summary_Table

--------------------—--------------------— RFM Analysis --------------------—--------------------—

go

create or alter view RFM_View as		-- Create View for RFM Analysis

with cte as (

select	customer_unique_id ,
		DATEDIFF(day , MAX(order_purchase_timestamp) , (select max(order_purchase_timestamp) from orders_dataset)) as Recency,
		count(distinct(oi.order_id)) as Frequency ,
		SUM(price) as Monetary

from customers_dataset as C

join orders_dataset O
on O.customer_id = C.customer_id

join order_items_dataset OI
on OI.order_id = o.order_id

group by customer_unique_id

) ,

cte_2 as (

select	* , 
		ROW_NUMBER() over(order by Recency asc) as R_rank ,
		ROW_NUMBER() over(order by Frequency desc) as F_rank ,
		ROW_NUMBER() over(order by Monetary desc) as M_rank

from cte

) ,

cte_3 as (

select	* ,
		NTILE(10) over(order by R_rank desc) R_Score ,
		NTILE(10) over(order by F_rank desc) F_Score, 
		NTILE(10) over(order by M_rank desc) M_Score

from cte_2

) ,

cte_4 as (

select	customer_unique_id ,
		Recency , 
		Frequency ,
		Monetary , 
		R_Score ,
		F_Score,
		M_Score ,
		(R_Score + F_Score + M_Score) as Total_Score 

from cte_3

)

select	* ,
		case 
			when Total_Score >= 27 then 'VIP Customers'
			when Total_Score >= 24 then 'Loyal Customers'
			when Total_Score >= 20 then 'Potential Customers'
			when Total_Score >= 17 then 'Promising'
			when Total_Score >= 15 then 'Engaged'
			when Total_Score >= 12 then 'Requires Attention'
			when Total_Score >= 10 then 'At Risk'
			else 'Lost/Inactive'
		end as Customer_Segment

from cte_4

go
							-- The End Of View 


select * from RFM_View order by Total_Score desc         -- Exec View 


							-- Totals For Customer_Segment

select Customer_segment , count(*) as Number_Of_Customers

from RFM_View

group by Customer_Segment

order by Number_Of_Customers desc

							-- Revenues For Customer_Segment

select Customer_segment , sum(Monetary) as Revenue

from RFM_View

group by Customer_Segment

order by Revenue desc

							-- Avg Spending For Customer_Segment

select Customer_segment , AVG(Monetary) as Avg_Spending

from RFM_View

group by Customer_Segment

order by Avg_Spending desc

							-- Avg Oreders For Customer_Segment

select Customer_segment , AVG(Frequency) as Avg_Orders

from RFM_View

group by Customer_Segment

order by Avg_Orders desc

                                  -- Percentage of Customers by Segment

select	Customer_segment , 
		count(*) as Customers ,
		cast(
		(count(*) * 100.0 / sum(count(*)) over()) 
		as decimal(5,2)) as Percentage_Of_Total_Customers

from RFM_View

group by Customer_Segment

order by Percentage_Of_Total_Customers desc




--------------------—--------------------— Monthly Active Customers (MAC) --------------------—--------------------—

go

create or alter view MAC as

select	DATEFROMPARTS(Year(order_purchase_timestamp) , Month(order_purchase_timestamp) ,1) Order_Month , 
		count(distinct(customer_unique_id)) Active_Customers 

from customers_dataset C
											       		
join orders_dataset O
on O.customer_id = C.customer_id

group by DATEFROMPARTS(Year(order_purchase_timestamp) , Month(order_purchase_timestamp) ,1)

go 

select * from MAC order by Order_Month asc       -- Exec View 


-------------------- Short-Term Monthly Retention --------------------

go

create or alter view Retention_Customers as 

with cte as (

select	distinct(customer_unique_id) ,
		DATEFROMPARTS(YEAR(order_purchase_timestamp) ,
		MONTH(order_purchase_timestamp), 1) as Order_Month

from customers_dataset C

join orders_dataset O
on O.customer_id = C.customer_id

) ,

cte_2 as (

select	* ,
		LEAD(Order_Month) over(partition by customer_unique_id 
		order by Order_Month) Next_Month

from cte

) ,

cte_3 as (

select	* ,
		DATEDIFF(MONTH, Order_Month, Next_Month) as Month_Diff

from cte_2 

)

select	Order_Month ,
		count(*) as Retained_Customer

from cte_3

where Month_Diff = 1

group by Order_Month 

go

select * from Retention_Customers order by Order_Month       -- Exec View 


-------------------- Retention Rate --------------------

select	MAC.Order_Month ,
		CAST((Retained_Customer * 100.0 / Active_Customers) as decimal (5,2)) as Retention_Rate

from MAC

join Retention_Customers 
on Retention_Customers.Order_Month = MAC.Order_Month


--------------------—--------------------— Cohort Analysis --------------------—--------------------—

go 

Create or alter view Cohort_Analysis as 

with Cohort as (

select  customer_unique_id ,
		DATEFROMPARTS(YEAR(MIN(order_purchase_timestamp)), MONTH(MIN(order_purchase_timestamp)), 1) as Cohort_Month

from customers_dataset C

join orders_dataset O
on O.customer_id = C.Customer_id

group by customer_unique_id


) ,

Customer_Orders as (

select	distinct customer_unique_id ,
		DATEFROMPARTS(YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp), 1) Order_Month

from customers_dataset C

join orders_dataset O
on C.customer_id = O.customer_id

) , 

Result as ( 

select	CH.customer_unique_id ,
		CH.Cohort_Month ,
		CO.Order_Month ,
		DATEDIFF(MONTH , CH.Cohort_Month , CO.Order_Month) Cohort_index

from Cohort CH

join Customer_Orders CO
on CO.customer_unique_id = CH.customer_unique_id

) ,

Retention_Table as (

select	Cohort_Month ,
		Cohort_index , 
		count(distinct(customer_unique_id)) Customers 

from Result 

group by Cohort_Month, Cohort_index

)

select	A.Cohort_Month ,
		A. Cohort_index,
		A.Customers ,
		CAST(A.Customers * 100.0 / B.Customers as decimal(5,2)) Retention_Rate
from Retention_Table A 

join Retention_Table B
on B.Cohort_Month = A.Cohort_Month
and B.Cohort_index = 0 

go

select * from Cohort_analysis order by Cohort_index -- Exec View 