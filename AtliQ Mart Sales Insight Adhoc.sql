-- Creating the database atliqMartSales
create database if not exists atliqMartSales;
-- Setting default database
use atliqMartSales;

-- Checking if data has been imported correctly from CSV
select count(*) from dim_customers;
select count(*) from dim_targets_orders;
select count(*) from dim_products;
select count(*) from dim_date;
select count(*) from fact_order_lines;
select count(*) from fact_orders_aggregate;

-- Some EDA

-- Customers Table
select * from dim_customers;
describe dim_customers;
select count(product_id) `Total Proudcts` from dim_products;
select count(distinct(product_name)) `Total Distinct Products` from dim_products;
select distinct(product_name) `Distinct Products` from dim_products;
select count(distinct(category)) `Distinct Categories` from dim_products;
select distinct category `Distinct Category Name` from dim_products;

-- Products Table
describe dim_products;
select * from dim_products;
select count(customer_id) `Total Customers` from dim_customers;
select count(distinct(customer_name)) `Total Distinct Customers` from dim_customers;
select distinct(customer_name) `Distinct Customers` from dim_customers;
select count(distinct(city)) `Distinct Citites` from dim_customers;
select distinct city `Distinct City Name` from dim_customers;

-- Date Table
select * from dim_date;
describe dim_date;
update dim_date
set date = str_to_date(date, "%Y-%m-%d");
alter table dim_date
change column date date Date;
select distinct year(date) from dim_date;
select distinct monthname(date) from dim_date;

-- Targets Orders Table
select * from dim_targets_orders;

-- Order Lines
select * from fact_order_lines;
describe fact_order_lines;
update fact_order_lines
set order_placement_date = str_to_date(order_placement_date, "%Y-%m-%d");
alter table fact_order_lines
change order_placement_date order_placement_date Date;
update fact_order_lines 
set agreed_delivery_date = str_to_date(agreed_delivery_date, "%Y-%m-%d");
alter table fact_order_lines
change agreed_delivery_date agreed_delivery_date Date;
update fact_order_lines
set actual_delivery_date = str_to_date(actual_delivery_date, "%Y-%m-%d");
alter table fact_order_lines
change actual_delivery_date actual_delivery_date Date;

-- Orders Aggregate
select * from fact_orders_aggregate;
describe fact_orders_aggregate;
update fact_orders_aggregate
set order_placement_date = str_to_date(order_placement_date, "%Y-%m-%d");
alter table fact_orders_aggregate
change order_placement_date order_placement_date Date;

-- Total Orders
select count(distinct(order_id)) `Total Orders`
from fact_order_lines;

-- Total Order Lines Vs Delivered Order Lines
select sum(order_qty) `Total Order Lines`, sum(delivery_qty) `Total Order Lines Delivered`, sum(order_qty) - sum(delivery_qty)  `Total Order Lines Undelivered`
from fact_order_lines;

-- Total Orders, Percentage Orders by City
with cte as
(select city, count(distinct(order_id)) `Total Orders`
from dim_customers
join fact_order_lines 
using (customer_id)
group by city)
select city City, `Total Orders`, concat(round(`Total Orders`/ sum(`Total Orders`) over() * 100, 2), '%') "Percentage Order"
from cte
group by city;

-- Total Orders, Percentage Orders by Customers
with cte as
(select customer_name, count(order_id) `Total Orders`
from dim_customers
join fact_orders_aggregate
using (customer_id)
group by customer_name)
select customer_name `Customer Name`, `Total Orders`, concat(round(`Total Orders`/ sum(`Total Orders`) over() * 100, 2), '%') "Percentage Order"
from cte
group by customer_name
order by `Total Orders` Desc;

-- Orders Placed by Month
select monthname(date) Month, count(distinct(order_id)) `Total Orders`, lag(count(order_id)) over(order by month(date)) `Total Orders PM`
from fact_orders_aggregate a
join dim_date d
on a.order_placement_date = d.date
group by Month, month(date)
order by month(date);

-- OT, IF, OTIF Orders by Customers
with ot as(
select customer_name, count(order_id) `OT`
from dim_customers
join fact_orders_aggregate
using (customer_id)
where on_time = 1
group by customer_name
),
inf as(
select customer_name, count(order_id) `IF`
from dim_customers
join fact_orders_aggregate
using (customer_id)
where in_full = 1
group by customer_name
),
otif as 
(
select customer_name, count(order_id) `OTIF`
from dim_customers
join fact_orders_aggregate
using (customer_id)
where otif = 1
group by customer_name
)
select ot.customer_name, `OT`, `IF`, `OTIF`
from ot join inf using(customer_name)
join otif using(customer_name) 
group by customer_name


