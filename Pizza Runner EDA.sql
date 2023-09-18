-- A. Pizza metrics

-- 1 How many pizzas were ordered
select
	count(order_id) as number_of_pizzas
from customer_orders;    

-- 2 How many unique customer orders were made
select
	count(distinct order_id) as number_of_customers
from customer_orders;    

-- 3 How many successful orders were delivered by each runner?
select 
	runner_id,
	count(*) as number_of_deliveries
from runner_orders
where cancellation is null
group by runner_id;    

-- 4 How many of each type of pizza was delivered
select 
	pn.pizza_name,
    count(*) number_of_pizza
from customer_orders c
	join pizza_names pn on c.pizza_id = pn.pizza_id
	join runner_orders rn on c.order_id = rn.order_id
where cancellation is null
group by pn.pizza_name ;
	


-- 5 How many Vegetarian and MeatLovers were ordered by each customer
select
	c.customer_id,
	count(case when pn.pizza_name = 'Vegetarian' then pn.pizza_name end) as count_of_vegetarian,
    count(case when pn.pizza_name = 'MeatLovers' then pn.pizza_name end) as count_of_meatlovers
from customer_orders c 
	join pizza_names pn on c.pizza_id = pn.pizza_id
 group by c.customer_id; 
 
-- 6 What was the maximum number of pizzas delivered in a single order
 select
	max(total) as max_no_of_orders
from    
	(select
		co.order_id,
		count(*) as total
	from runner_orders ro
		join customer_orders co on ro.order_id = co.order_id
	where cancellation is null
	group by 1) as total_orders;   
    
-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes
select
		co.customer_id,
        count(case when co.exclusions is not null or co.extras is not null then 1 end) as at_least_one_change,
        count(case when co.exclusions is null and co.extras is null then 1 end) as no_change
from customer_orders co
			join runner_orders ro on co.order_id = ro.order_id
where cancellation is null
group by co.customer_id; 

-- 8 How many pizzas were delivered that had exclusion  
select
 count(*) as pizza_with_exclusion_extras
 from customer_orders co
	join runner_orders ro on co.order_id = ro.order_id
 where ro.cancellation is null
	and co.exclusions is not null
    and co.extras is not null;

-- 9 What was the total volume of pizzas ordered for each hour of the day
select	
		extract(hour from order_time) as hour_of_the_day,
        count(order_id) as volume_of_pizza_ordered 
from customer_orders
group by  hour_of_the_day; 

-- 10 What was the volume of orders for each day of the week
select 
	dayofweek(order_time) as day_of_the_week,
    dayname(order_time) as day_name,
    count(pizza_id) as volume_of_orders
from customer_orders
group by day_of_the_week, day_name;    
    
-- B. Runner and Customer Experience metrics

-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
	week(date_add(registration_date, interval 3 day)) as start_week_num,
    count(*) as total_runner
from runners
group by start_week_num
order by start_week_num;   

-- 2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
 select
	runner_id,
round(avg(timestampdiff(minute,co.order_time, ro.pickup_time))) as average_minutes
from customer_orders co
	join runner_orders ro on co.order_id = ro.order_id
 group by runner_id
 order by average_minutes;   
    
-- 3 is there a relationship between the number of pizzas and how long it takes to prepare
with number_of_pizza as (
select	
	co.order_id,
	co.order_time,
    ro.pickup_time,
    count(co.pizza_id) as count_of_pizza
from customer_orders co
	join runner_orders ro on co.order_id = ro.order_id
group by
	co.order_id,
	co.order_time,
    ro.pickup_time)
    
select 
	count_of_pizza,
    round(avg(timestampdiff(minute,order_time,pickup_time))) as avg_time
from number_of_pizza
group by count_of_pizza;   
    
-- 4 What was the average distance travelled for each customer
select
	co.customer_id,
    round(avg(distance)) as avg_distance_km
  from customer_orders co
	join runner_orders ro on co.order_id = ro.order_id
group by co.customer_id
order by avg_distance_km desc;    
    
-- 5 What is the difference between the longest and shortest delivery times for all orders
select
	max(duration) as max_duration,
	min(duration) as min_duration,
	max(duration) - min(duration) as time_difference
from runner_orders;    
 
-- 6 What was the average speed for each runner for each delivery and do you notice any trend in these values
select
	ro.order_id,
    r.runner_id,
    round(avg((ro.distance * 1000) / (ro.duration * 60))) as average_speed_kmh
from runner_orders ro 
	join runners r on ro.runner_id = r.runner_id
where cancellation is null
group by	
  ro.order_id,
  r.runner_id;  
		
-- 7 What is the successful delivery percentage for each runner
select
	runner_id,
	concat(round(
    100 * (count(case 
		when cancellation is null then order_id end) / count(*) )), '%') as delivery_rate
from runner_orders
group by runner_id;        
    
-- B. Pricing and Ratings metrics    

-- 1 If a MeatLovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes, how much has Pizza Runner made so far if there are no delivery fees
select	
	sum(case
		when pizza_name = 'Meatlovers' then 12
        else 10
	 end) as amount_made
from customer_orders co
	join pizza_names pn on co.pizza_id = pn.pizza_id
    join runner_orders ro on co.order_id = ro.order_id
where cancellation is null;    

-- 2 What if there was an additional $1 charge for any pizza extras
with total_price as (
select
co.*,
pizza_name,
	case
		when pizza_name = 'Meatlovers' then 12
        else 10 end as pizza_price,
    case
		when length(extras) >= 1 then length(trim(replace(extras,', ',''))) * 1
        else 0 end as extra_price
from customer_orders co
	join pizza_names pn on co.pizza_id = pn.pizza_id
    join runner_orders ro on co.order_id = ro.order_id
where cancellation is null
)    
        
select 
	sum(pizza_price + extra_price) as amount_made
from total_price;    
    
-- If a MeatLovers pizza was $12 and Vegetarian $10 fixed prices with no extra cost and a runner is paid $0.30 per km travelled, how much money does Pizza Runner have left over after deliveries
with price as (
select
	sum(pizza_price) as total_pizza_price
from
	(select
		pn.pizza_name,
		case
			when pn.pizza_name = 'Meatlovers' then 12
			else 10
		end as pizza_price
	from runner_orders ro
		inner join customer_orders co on ro.order_id = co.order_id
		inner join pizza_names pn on co.pizza_id = pn.pizza_id
	where ro.cancellation is null) as pr
),
payment as (
select
	sum(pay) as runner_payment
    from
(select
	distance * 0.3 as pay
from runner_orders
where distance is not null) as pay
)
select (total_pizza_price - runner_payment)	as amount_left
from price, payment;