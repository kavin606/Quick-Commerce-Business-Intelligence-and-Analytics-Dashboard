create database Quick_commerce_Analysis;

select * from customers;

select * from delivery;

select * from delivery_person;

select * from feedback;

select * from orders;

select * from order_status;

select * from products;

select * from refund;

select * from services;

select * from transactions;

-- 	1.What is the Total Feedback Per Month?
-- 	2.	What is the Total Paid Revenue (considering only transactions where payment_status = ‘Success’)?
-- 	3.	What is the Total Processed Refund Amount (refund_status = ‘Processed’)?
-- 	4.	What is the Final Net Revenue (Total Paid Revenue – Total Processed Refund Amount)?
-- 	5.	What is the Month-over-Month Revenue Growth Percentage?
-- 	6.	What is the Average Order Value (Net Revenue / Total Successful Orders)?
-- 	7.	What percentage of total revenue comes from Products vs Services?
-- 	8.	How many total customers have placed at least one order?
-- 	9.	What is the monthly new customer acquisition  based on signup_date?
-- 	10.	What percentage of customers are repeat customers (customers with more than one order)?
-- 	11.	What is the average number of orders per customer?
-- 	12.	Who are the Top 10 customers by Net Revenue (use ranking function)?
-- 	13.	What is the Customer Lifetime Value (CLV) for each customer?
-- 	14.	What are the Top 10 products by revenue (use ranking function)?
-- 	15.	What are the Top 5 services by revenue?
-- 	16.	Which product or service category generates the highest revenue?
-- 	17.	What is the category-wise Month-over-Month revenue growth percentage?
-- 	18.	What is the overall order cancellation rate (based on order_status table)?
-- 	19.	What is the average delivery time (difference between order_date and delivery_date)?
-- 	20.	What percentage of orders were delivered after the ETA?
-- 	21.	Which delivery person has handled the highest number of deliveries?
-- 	22.	What is the average delivery time per delivery person?
-- 	23.	What is the payment success rate (successful transactions / total transactions)?
-- 	24.	What is the revenue distribution by payment mode?
-- 	25.	What is  Delivered vs Cancelled Orders?
-- 26. What is the total number of orders placed on the platform?
-- 27. What is the total number of completed deliveries?
-- 28. What is the total quantity of items sold across all orders?
-- 29. What is the On-Time Delivery Percentage (orders delivered on or before ETA)?
-- 30. What is the Peak Order Hour based on order_time?
-- 31. What is the percentage of Low Ratings (ratings ≤ 2) received from customers?
-- 32. What is the total number of feedback entries submitted by customers?
-- 33. What is the Feedback Response Rate (percentage of feedback responded by the company)?
-- 34. What is the Month-over-Month (MoM) Growth Percentage in Total Orders?
-- 35. What is the total refund amount issued (irrespective of refund status)?

-- 1.What is the Total Feedback Per Month?
select date_format(feedback_date,'%Y-%m') as month,count(*) as feedback_count
from feedback
group by 1
order by month;

-- 2. What is the Total Paid Revenue (considering only transactions where payment_status = ‘Success’)?

select round(sum(transaction_amount),2)  as total_paid_revenue from transactions where payment_status = 'Success';

-- 	3.	What is the Total Processed Refund Amount ?

select sum(refund_amount)as total_refund_amount from refund ;

-- 	4.	What is the Final Net Revenue (Total Paid Revenue – Total Processed Refund Amount)?

select sum(t.transaction_amount - r.refund_amount) as final_net_revenue
from transactions t
left join refund r 
on t.order_id = r.order_id;


-- 	5.	What is the Month-over-Month Revenue Growth Percentage?


-- Month_over_month Growth % = (Current_month_growth - previous_month_growth) / Previous_month_growth * 100

WITH monthly_revenue AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS month, SUM(transaction_amount) AS total_revenue
    FROM transactions
    GROUP BY 1
)

SELECT month,total_revenue,ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY month)
        ) / (LAG(total_revenue) OVER (ORDER BY month)) * 100,0) AS mom_growth_percentage
FROM monthly_revenue;

-- 	6.	What is the Average Order Value (Net Revenue / Total Successful Orders)?

-- Average order value = Net revenue / total successful order 
-- Final Net Revenue (Total Paid Revenue – Total Processed Refund Amount)

select * from transactions;
select * from customers;
select * from refund;
select * from orders;

create table net_revenue as 
select t.order_id,c.cust_id, sum(t.transaction_amount - ifnull(r.refund_amount,0)) as Final_net_revenue  from transactions t
left join refund r on t.order_id = r.order_id 
join orders o on t.order_id = o.order_id
join customers c on o.cust_id = c.cust_id
GROUP BY t.order_id, c.cust_id;

SELECT ROUND((SUM(t.transaction_amount) - SUM((r.refund_amount)))/ COUNT(DISTINCT t.order_id),2) AS average_order_value
FROM transactions t
LEFT JOIN refund r 
    ON t.order_id = r.order_id;


select * from net_revenue;

-- 7. What percentage of total revenue comes from Products vs Services?

select * from transactions;
select * from services;
select * from products;

WITH order_revenue AS (
    SELECT 
        o.item_type,
        t.order_id,
        t.transaction_amount - SUM(r.refund_amount) AS net_revenue
    FROM transactions t
    JOIN orders o 
        ON t.order_id = o.order_id
    LEFT JOIN refund r 
        ON t.order_id = r.order_id
    GROUP BY o.item_type, t.order_id, t.transaction_amount
)

-- select * from order_revenue
-- SELECT 
--     item_type,ROUND(SUM(net_revenue) * 100 / SUM(SUM(net_revenue)) over() ,2) AS revenue_percentage
-- FROM order_revenue
-- GROUP BY item_type;

SELECT item_type,
    ROUND(SUM(net_revenue) * 100/
        (
            SELECT SUM(net_revenue)
            FROM order_revenue),2) AS revenue_percent
FROM order_revenue
GROUP BY item_type;


-- 8.How many total customers have placed at least one order?


SELECT COUNT(DISTINCT cust_id) AS total_active_customers from orders;

-- 9.What is the monthly new customer acquisition based on signup_date?


select * from customers;

SELECT  COUNT(cust_id) AS new_customers, DATE_FORMAT(signup_date, '%Y-%m') AS month FROM customers
GROUP BY 2
ORDER BY 2;


-- 10.What is the monthly new customer acquisition based on signup_date? (Show trend in percentage)

-- (Current month customers - pervious month customers / previous month customers) * 100

with Monthly_sign_up as (
	SELECT  COUNT(cust_id) AS new_customers, DATE_FORMAT(signup_date, '%Y-%m') AS month FROM customers
		GROUP BY 2
		ORDER BY 2
)


select new_customers,month,(new_customers - LAG(new_customers) OVER(order by month))/ LAG(new_customers) OVER(order by month) *100 as growth_percentagse
from Monthly_sign_up;

-- 	11.	What is the average number of orders per customer?

-- Avg order per customer = Total order / total customers placed the order

SELECT AVG(order_count)AS avg_orders_per_customer
FROM (
    SELECT cust_id,count(order_id) AS order_count
    FROM orders
    GROUP BY cust_id
) t;

-- 12.	Who are the Top 10 customers by Net Revenue (use ranking function)?

select cust_id , sum(final_net_revenue) as total_net_revenue ,
rank() over(order by sum(final_net_revenue)desc) as Ranking
from net_revenue
group by 1
order by 3 asc
limit 10;

-- 13. What is the Customer Lifetime Value (CLV) for each customer?

-- as we already have net_revenue

-- Customer Lifetime Value (CLV) = Sum(net revenue of all the orders by the customers)

SELECT cust_id,sum(final_net_revenue) as customer_lifetime_value
FROM net_revenue
GROUP BY cust_id;

-- 14.What are the Top 10 products by revenue (use ranking function)?

select * from products;

SELECT *
FROM (
    SELECT p.prod_id,
        sum(n.final_net_revenue) AS total_revenue,
        RANK() OVER (ORDER BY SUM(n.final_net_revenue) DESC) AS product_rank
    FROM net_revenue n
    JOIN orders o 
        ON n.order_id = o.order_id
    JOIN products p 
        ON o.prod_id = p.prod_id
    WHERE o.item_type = 'product'
    GROUP BY p.prod_id
) ranked_products
WHERE product_rank <= 10;

-- 15.What are the Top 5 services by revenue?

SELECT * FROM (
    SELECT s.service_id,
        ROUND(SUM(n.final_net_revenue), 2) AS total_revenue,
        RANK() OVER (ORDER BY SUM(n.final_net_revenue) DESC) AS service_rank
    FROM net_revenue n
    JOIN orders o 
        ON n.order_id = o.order_id
    JOIN services s 
        ON o.service_id = s.service_id
    WHERE o.item_type = 'service'
    GROUP BY s.service_id
) ranked_services
order by total_revenue desc
limit 5;

-- 16.	Which product or service category generates the highest revenue?

select * from products;
select * from services;

select *
from (
    select p.category,
        round(sum(n.final_net_revenue), 2) as total_revenue,
        rank() over (order by sum(n.final_net_revenue) desc) as rnk
    from net_revenue n
    join orders o on n.order_id = o.order_id
    join products p on o.prod_id = p.prod_id
    where o.item_type = 'product'
    group by p.category
) t
where rnk = 1

union all

select *
from (
    select s.category,
        round(sum(n.final_net_revenue), 2) as total_revenue,
        rank() over (order by sum(n.final_net_revenue) desc) as rnk
    from net_revenue n
    join orders o on n.order_id = o.order_id
    join services s on o.service_id = s.service_id
    where o.item_type = 'service'
    group by s.category
) t
where rnk = 1;

-- 	17.	What is the category-wise Month-over-Month revenue growth percentage (products) ?

-- Month-over-Month revenue growth percentage = current month revenue - previous month revenue/ current month revenue

with monthly_category_revenue as (
    select p.category,
        date_format(o.order_date, '%y-%m') as month,sum(n.final_net_revenue) as total_revenue
    from net_revenue n
    join orders o on n.order_id = o.order_id
    join products p on o.prod_id = p.prod_id
    where o.item_type = 'product'
    group by 1, 2
)

select category,month,round(total_revenue,2) as total_revenue,round((total_revenue - lag(total_revenue) over (partition by category order by month))
        /lag(total_revenue) over (partition by category order by month) * 100,2) as mom_growth_percentage
from monthly_category_revenue
order by 1, 2;

-- 	18.	What is the overall order cancellation rate (based on order_status table)?

select * from order_status;

select round(count(distinct 
			case 
            when status_name = 'Cancelled' 
            then order_id end) * 100/count(distinct order_id),2) as cancellation_rate_percentage
from order_status;


-- 20.What is the average delivery time (difference between order_date and delivery_date)

select * from order_status;
select * from orders;
select * from delivery;


select (avg(time_to_sec(timediff(delivery_time, pickup_time)) / 60 ))
as delivery_time_minutes
from delivery;

    
-- 21.Which delivery person has handled the highest number of deliveries?

 select * from delivery_person;
 select * from delivery;
 select * from orders;
 
select *
from (
    select 
        dp.delivery_person_name,count(d.order_id) as total_deliveries,rank() over (order by count(d.order_id) desc) as rnk
    from delivery d
    join delivery_person dp
        on d.delivery_person_id = dp.delivery_person_id
    group by dp.delivery_person_name
) t
where rnk = 1;
-- 22.What is the average delivery time per delivery person?


select dp.delivery_person_name,
round(avg(d.delivery_duration_minutes), 2) as avg_delivery_time_minutes
from delivery d
join delivery_person dp 
    on d.delivery_person_id = dp.delivery_person_id
group by 1
order by 2;

-- 23.	What is the payment success rate (successful transactions / total transactions)?

SELECT ROUND(
        (SELECT COUNT(*) FROM transactions 
         WHERE payment_status = 'Success') * 100.0 / COUNT(*),2) AS payment_success_rate_percentage
FROM transactions;

-- 24.What is the revenue distribution by payment mode?

-- Revenue Distribution = Revenue per payment mode/Total Revenue)* 100

select t.payment_method,round(sum(n.final_net_revenue), 2) as total_revenue,
round(sum(n.final_net_revenue) * 100/ sum(sum(n.final_net_revenue)) over(),2) as revenue_percentage
from net_revenue n
join transactions t on n.order_id = t.order_id
where t.payment_status = 'Success'
group by t.payment_method
order by total_revenue desc;

-- 25. Delivered vs Cancelled Orders

select delivery_status,count(*) as total
from delivery
group by 1;

-- 26. total number of orders placed on the platform

select count(order_id) as total_orders
from orders;

-- 27. total number of completed deliveries
select count(order_id) as total_deliveries
from delivery
where delivery_status = 'delivered';

-- 27. total number of completed deliveries

select count(order_id) as total_deliveries
from delivery
where delivery_status = 'delivered';

-- 28. total quantity of items sold across all orders

select sum(qty) as total_quantity_sold
from orders;

-- 29. on-time delivery percentage (orders delivered on or before eta)
select round(sum(case when delivery_duration_minutes <= 30 then 1 else 0 end) / count(*) * 100, 2) as on_time_percentage
from delivery;

-- 30. peak order hour based on order_time
select order_hour, total_orders
from (
    select hour(order_time) as order_hour,count(order_id) as total_orders,
    rank() over (order by count(order_id) desc) as rnk
    from orders
    group by hour(order_time)) ranked
where rnk = 1;

-- 31. percentage of low ratings (ratings <= 2)
select round(sum(case when rating <= 2 then 1 else 0 end)
/ count(*) * 100, 2
) as low_rating_percentage
from feedback;

-- 32. total number of feedback entries
select count(feedback_id) as total_feedback_entries
from feedback;

-- 33. total feedback  count

select count(feedback_id) as total_feedback
from feedback;

-- 34. month-over-month growth percentage in total orders
with monthly_orders as (
    select date_format(order_date, '%y-%m') as month,count(order_id) as total_orders
    from orders
    group by 1
)
select month,
round(
(total_orders - lag(total_orders) over (order by month))
/ lag(total_orders) over (order by month) * 100, 2
) as mom_growth_percentage
from monthly_orders;

-- 35. total refund amount issued (
select sum(refund_amount) as total_refund_amount
from refund;

-- To work on
-- Optional advanced KPIs:
-- 	•	customer retention cohort
-- 	•	revenue contribution of top 20% customers
-- 	•	cancellation rate by category
-- 	•	delivery delay percentage
-- 	•	repeat purchase frequency trend
