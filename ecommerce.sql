create database ecommerce;
use ecommerce;
rename table ecom_customers to customers,
	ecom_order_items to order_items,
    ecom_orders to orders,
    ecom_products to products;
select * from order_items;

# Which products generate the most revenue? A look at the top 10 product by revenue.
alter table order_items
add revenue decimal(10,2)
generated always as (quantity * item_price);

/* NOTE:
It is better to create an entirely new column for "Revenue" if we are going to use it a lot for referencing
*/


with top_ten as (select product_id, 
					sum(revenue) as total_revenue 
            from order_items 
            group by product_id 
            order by total_revenue desc limit 10)
select 
	p.product_name,
    tp.total_revenue
from top_ten as tp
join products p on tp.product_id=p.product_id;

select * from orders;

-- Top 10 customers by revenue: Which customers contribute the most to revenue

with top_customers as (select customer_id, round(sum(total_amount) ,2) as total_revenue from orders group by customer_id order by total_revenue desc limit 10)
select c.first_name,
		c.last_name,
        tc.total_revenue
from top_customers as tc
join customers c on c.customer_id=tc.customer_id;

-- Top 10 Countries by revenue

select * from customers;

select 
	c.country,
    format(sum(o.total_amount),2) as revenue
from customers c
join orders o on c.customer_id=o.customer_id
group by c.country
order by revenue desc limit 10;

-- Average Order Value (AOV)
## How much is spent per order by country
select 
	c.country,
    round(sum(o.total_amount)/count(o.order_id),2) as AOV
from
customers c
join 
orders o on o.customer_id=c.customer_id
group by c.country order by AOV desc limit 10;
select * from orders;

## How much does a customer spend per order

with cte as (select 
	customer_id,
    format(sum(total_amount)/count(order_id),2) as aov
    from orders 
    group by customer_id  order by aov desc limit 10)
select
	ct.customer_id,
    c.first_name,
    c.last_name,
      ct.aov
from cte ct
join customers c
		on c.customer_id=ct.customer_id;
    select * from products;

## bundled products
select
	a.product_id,
    b.product_id,
   # concat(p.product_name, 'and', t.product_name),
    count(*) as frequency
from
	order_items a 
join order_items b
	on a.order_id=b.order_id
    and a.product_id<b.product_id
group by a.product_id,b.product_id
order by frequency desc ;

## Include the product names in the final outcome.
select
	a.product_id,
    b.product_id,
    p.product_name,
    pt.product_name,
   # concat(p.product_name, 'and', t.product_name),
    count(*) as frequency
from
	order_items a 
join order_items b
	on a.order_id=b.order_id
    and a.product_id<b.product_id
join products p on p.product_id=a.product_id
join products pt on pt.product_id=b.product_id
group by a.product_id,b.product_id, p.product_name,pt.product_name
order by frequency desc limit 10;

## Pareto 

select * from orders;

with order_segments as (select 
	order_id,
    total_amount,
	case
		when total_amount> (select avg(total_amount) from orders) then "High Value"
        else "standards"
        end as category
from orders)

select 
	category,
    count(*) as order_count,
    format(sum(total_amount),2) as segment_revenue,
    round((sum(total_amount)/(select sum(total_amount) from orders))*100,2) as pct_of_revenue
from order_segments
group by category;

# YoY Revenue growth
select * from orders;
with yearly_revenue as (
						select 
							year(order_date) as sales_year,
							format(sum(total_amount),2) as total_revenue
                        from orders
                        group by sales_year
                        )
select 
	sales_year,
    total_revenue,
    lag(total_revenue) over (order by sales_year) as last_year_revenue,
    round( 
    (
    (total_revenue -  lag(total_revenue) over (order by sales_year))/ 
    lag(total_revenue) over (order by sales_year)
    )*100,2) as YoY_percent_growth
from yearly_revenue;
    
select * from orders;

select 
	customer_id,
    count(order_id) as order_frequency,
    format(sum(total_amount),2) as order_value
from orders
group by customer_id
order by order_frequency desc;
