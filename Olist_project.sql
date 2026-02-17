# Business Overview

#Q1: Total Revenue?
select 
round(sum(price),2) as total_revenue
from order_items;


#Q2: Total Orders?
SELECT 
count(distinct order_id) As total_orders
from orders;    
    
    
 #Q3: Total_customers?   
SELECT
count(customer_id) As total_customers
from customers;    


#Monthly Trends 
   
#Q4: Overall margin %    
with data as (select 
		sum(oi.price) as revenue, sum(oi.price-oi.freight_value) as profit
        from order_items as oi
        join orders as o
        on oi.order_id=o.order_id)
select revenue,profit,
		round((profit)/revenue*100,2) as overall_margin_percentage
        from data;


#Q5: Revenue trend
select date(o.order_purchase_timestamp) as order_date,
		sum(oi.price) as daily_revenue,
        sum(sum(oi.price)) OVER (order by date(o.order_purchase_timestamp)) as running_total
from order_items as oi
join orders as o 
	on oi.order_id = o.order_id
group by order_date
order by running_total;


#Q6: Order growth
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') date,
    COUNT(distinct order_id) AS total_orders
FROM orders
GROUP BY date
ORDER BY date;


#Q7: Average Order Value Trend!
with order_data as (
	select DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
		sum(oi.price) as total_revenue,
		count(distinct o.order_id) as total_orders
          FROM orders o
		  JOIN order_items oi 
			ON o.order_id = oi.order_id
		group by month )
select month, total_revenue, total_orders,
		round(total_revenue/total_orders,2) as avg_order_value
        from order_data
        order by month ;


# Items per Order (Cart Size)
select  DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS months,
		round(count(p.product_id)/count(distinct o.order_id)) as avg_order         #total products sold upon distinct orders
        from products as p
         join order_items as oi
        on p.product_id=oi.product_id
        join orders as o
			on oi.order_id=o.order_id
        group by months
        order by months;
       
       
#Q8: Margin trend!
with data as (select DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') as months,
		sum(oi.price) as revenue, sum(oi.price-oi.freight_value) as profit
        from order_items as oi
        join orders as o
        on oi.order_id=o.order_id
        group by months),
        
margin as ( select months, profit, revenue,
			round(profit/revenue*100,2) as  profit_margin_percent
            from data )
select *
from margin
order by months;
    
    
#Shipping Impact

#Q9: Freight as % of revenue
with data as (select DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') as months,
		sum(oi.price) as revenue, sum(oi.freight_value) as freight
        from order_items as oi
        join orders as o
        on oi.order_id=o.order_id
        group by months),
        
freightening as ( select months, freight, revenue,
			round(freight/revenue*100,2) as  freight_margin_percent
            from data )
select *
from freightening
order by months;     
    
    
#Q10: Revenue by category    
select p.product_category_name,
		round(sum(price),2) as total_revenue
        from order_items as oi
        join products as p
        on oi.product_id=p.product_id
        group by product_category_name
        order by total_revenue desc;
        
        
#Q11: Margin by category
with data as (select p.product_category_name,
		sum(oi.price) as revenue, sum(oi.price- COALESCE(oi.freight_value,0)) as profit      #coalesce to treat all null values as 0
        from order_items as oi
        join products as p
        on oi.product_id=p.product_id
        group by product_category_name),
        
margin as ( select product_category_name, profit, revenue,
			round(profit/revenue*100,2) as  profit_margin_percent
            from data )
select *
from margin
order by  profit_margin_percent desc;		
    
    
#Q12: Category contribution shift
 with data as (select p.product_category_name,
		sum(oi.price) as revenue
        from order_items as oi
        join products as p
        on oi.product_id=p.product_id
        group by product_category_name),
        
margin as ( select product_category_name, revenue,
			round(revenue/sum(revenue) OVER() *100,2) as  percent_contribution           #sum() over() when multiple categories always use groupby or order by after it
            from data )
select *
from margin
order by percent_contribution desc;   
 
 
#Risk Areas
   select  sum(oi.price-oi.freight_value) as total_loss,
			count(distinct order_id) as loss_orders
	from order_items as oi
    where  oi.price<oi.freight_value;
    

#Find first order month per customer and number of new customers each month
with first_order as (select c.customer_id , MIN(DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m')) as first_month
				from orders as o
				join customers as c
					on o.customer_id=c.customer_id
				group by customer_id)
select customer_id,first_month,
ROW_NUMBER() OVER(PARTITION BY first_month ORDER BY first_month) as new_customers
from first_order
group by customer_id
order by first_month;
   
 
#Top 20% Products Revenue Contribution
with data_pro as (select p.product_id, sum(oi.price) as total_revenue
		from order_items as oi
        join products as p
        on oi.product_id=p.product_id
        group by product_id),
        
 ranked as (select product_id, total_revenue,
			NTILE(5) OVER(ORDER BY total_revenue desc) as rev_percentile      #never round ntile, never groupby on middle query
            from data_pro)
            
select                                   #when u want single value than dont write shits in last query select
		round(sum(case when rev_percentile=1 then total_revenue  else 0 end)/sum(total_revenue) *100,2) as percent_contribution
        from ranked;          
# One row → Use normal SUM() ✅ Multiple rows + need overall total → Use SUM() OVER()   


#Order Value Distribution
select 
	case
		when price <100 then 'low' 
		when price  between 100 and 500 then 'medium'
        else 'high'
	end as price_table,
count(*) as total_orders
from order_items as oi
group by price_table;

#Region-Level Performance
#Revenue by state
select c.customer_state,
						sum(oi.price) as total_revenue 
				from order_items as oi
                join orders as o
                on oi.order_id=o.order_id
                join customers as c
                on o.customer_id=c.customer_id
                group by customer_state 
                order by total_revenue desc;
    
    
#Profit by state
select c.customer_state,
						sum(oi.price-oi.freight_value) as total_profit
				from order_items as oi
                join orders as o
                on oi.order_id=o.order_id
                join customers as c
                on o.customer_id=c.customer_id
                group by customer_state 
                order by total_profit desc;
    
    
#Freight-heavy regions
select c.customer_state,
						sum(oi.freight_value) as total_freight_value
				from order_items as oi
                join orders as o
                on oi.order_id=o.order_id
                join customers as c
                on o.customer_id=c.customer_id
                group by customer_state 
                order by total_freight_value desc;
  
  
 # Month-over-Month Growth Rate?
WITH monthly_revenue as (
	SELECT
		DATE_FORMAT(o.order_purchase_timestamp , '%y-%m') as months,
        sum(oi.price) as revenue
	from order_items as oi
    join orders as o 
		on oi.order_id=o.order_id
    group by months)
    
SELECT months,revenue,
		lag(revenue) OVER(order by months) as previous_year_revenue,
        ROUND((revenue-lag(revenue) OVER(order by months))/lag(revenue) OVER(order by months)*100,2) as growth_percentage
from monthly_revenue;   


# ***Customer Quality Analysis
# Repeat Customer Revenue Contribution
with data_c as (select customer_id,
						count(o.order_id) as total_orders
						from orders as o
					    group by customer_id)
select 
		case when total_orders=1 then 'single time'
			else 'repeat'
            end as cust_table,
		count(*) as total_customers
from data_c
group by cust_table;


#Repeat customer AOV vs One-time AOV
with data_c as (select customer_id,
						count(*) as total_orders,
                         SUM(COALESCE(oi.price,0)) AS customer_revenue
						from order_items as oi
                        join orders as o
                        on oi.order_id=o.order_id
					    group by customer_id)
 select 
		AVG(case when total_orders>1 then customer_revenue end) as repeaters_revenue_avg,
        AVG(case when total_orders=1 then customer_revenue end) as single_Timers_revenue_avg
        from data_c;
        
        
# Revenue from Repeat Customers
with data_c as (select customer_id,
						count(*) as total_orders,
                         SUM(COALESCE(oi.price,0)) AS customer_revenue
						from order_items as oi
                        join orders as o
                        on oi.order_id=o.order_id
					    group by customer_id)
 select 
		SUM(case when total_orders>1 then customer_revenue end) as repeaters_revenue
        from data_c;
 
#% Revenue Contribution from Repeat Customers
with data_c as (select customer_id,
						count(*) as total_orders,
                         SUM(COALESCE(oi.price,0)) AS customer_revenue
						from order_items as oi
                        join orders as o
                        on oi.order_id=o.order_id
					    group by customer_id)
 select 
		round(SUM(case when total_orders>1 then customer_revenue end)/sum(customer_revenue)*100,2) as percent_contribution_repeaters
          from data_c;
  
 
# Number of customers who ordered more than once Retention rate    ie no. of customers who ordered more than once upon distinct customers
 with data_c as (select o.customer_id,
						count(o.order_id) as total_orders
                        from orders as o
					    group by customer_id)
 select 
		round(SUM(case when total_orders>1 then 1 else 0 end)/count(*)*100,2) as repeaters_retention_rate
          from data_c;
          
          
# Operational Risk Analysis
# Freight % by Month
with data_1 as (select DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') as months ,sum(oi.price) as total_revenue ,sum(oi.freight_value) as freight
				from order_items as oi                                           #in querie's select u need to put values that u need in this query and the next query too
				join orders as o 
						on oi.order_id=o.order_id
				group by months) ,
data_2 as (select months,
			round(freight/(total_revenue)*100,2) as freight_percentage
			from data_1)
select *
from data_2
order by months;    
 
 #SHORTER N BETTER
 
 SELECT 
    DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS month,
    ROUND(SUM(oi.freight_value) / SUM(oi.price) * 100, 2) AS freight_percent
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY month;

    
#Customer Lifetime Value (CLV) Approximation
select o.customer_id, count(DISTINCT o.order_id) as total_orders, sum(oi.price) as total_revenue, avg(oi.price) as average_order_value
		from order_items as oi
        join orders as o
        on oi.order_id=o.order_id
        group by customer_id
        order by total_revenue desc;
   

#Churn Indicator (inactive customers from past 3 months)
with data_1 as ( select customer_id,
						MAX(order_purchase_timestamp) as last_order
                        from orders
                        group by customer_id)
select count(*) as churned_customers
		from data_1
        where last_order < DATE_SUB(  (SELECT MAX(order_purchase_timestamp) from orders),INTERVAL 3 month) ;   #*******


    
   

    
    
    
    
    
    
    
    
    
    
    
    
    
    WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM orders as o
    join customers as c
    on o.customer_id=c.customer_id
    GROUP BY customer_unique_id
)

SELECT 
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)* 100.0
        / COUNT(*) 
    ,2) AS repeat_customer_rate
FROM customer_orders;

    
    
  SELECT 
    COUNT(*) AS repeat_customers
FROM (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) t;
  
    
    
    
    SELECT 
    MAX(total_orders) AS max_orders_per_customer
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) t;

    SELECT COUNT(*) FROM orders;

    
    