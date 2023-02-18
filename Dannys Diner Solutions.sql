/**********************

Case Study Questions
Each of the following case study questions can be answered using a single SQL statement:

What is the total amount each customer spent at the restaurant?
How many days has each customer visited the restaurant?
What was the first item from the menu purchased by each customer?
What is the most purchased item on the menu and how many times was it purchased by all customers?
Which item was the most popular for each customer?
Which item was purchased first by the customer after they became a member?
Which item was purchased just before the customer became a member?
What is the total items and amount spent for each member before they became a member?
If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

************************/

use dannys_diner;
show tables;

create view xmembers as select * from members;
create view xmenu as select * from menu;
create view xsxmenuales as select * from sales;


-- What is the total amount each customer spent at the restaurant?
with cust_sales as (
	select * 
    from sales s
    join menu m
    on s.product_id = m.product_id )
select * from cust_sales;


-- How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as visit_days 
from sales
group by customer_id;


-- What was the first item from the menu purchased by each customer?
select s.customer_id, m.product_name as first_order
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id
order by s.order_date;

			-- alternate sloution
with menu_sales as
	(select s.customer_id, m.product_name, s.order_date 
	from sales s
	join menu m
	on s.product_id = m.product_id
    )
select customer_id, product_name as first_order from 
	(select customer_id, product_name, row_number() over(partition by customer_id order by order_date) as rnk
	from menu_sales) x
where x.rnk = 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select customer_id, count(product_id) as ntimes_ordered_famous_item
from sales 
where product_id = 
	(select product_id 
	from sales
	group by product_id
	order by count(product_id) desc
	limit 1) 
group by customer_id;


-- Which item was the most popular for each customer?
with temp as
	(select customer_id, product_id, count(product_id) as ntimes_ordered 
			-- ,rank() over(partition by customer_id)as rnk
	from sales
	group by customer_id, product_id
	order by customer_id, ntimes_ordered desc)
select customer_id, product_id as most_purchased_prodcut, ntimes_ordered from 
	(select *, row_number() over(partition by customer_id) as rnk
	from temp) x
where x.rnk = 1;


-- Which item was purchased first by the customer after they became a member?
with all_join as
	(select s.*, m.product_name 
	from sales s
	join menu m
	on s.product_id = m.product_id
    join members mem 
    on s.customer_id = mem.customer_id
    where s.order_date >= mem.join_date
    )
select customer_id, product_name as first_order_after_membership 
from all_join
group by customer_id
order by order_date;


-- Which item was purchased just before the customer became a member?
with all_join as
	(select s.*, m.product_name 
	from sales s
	join menu m
	on s.product_id = m.product_id
    join members mem 
    on s.customer_id = mem.customer_id
    where s.order_date < mem.join_date
    )
select  customer_id, product_name as last_order_before_membership 
from all_join
group by customer_id
order by order_date desc;


-- What is the total items and amount spent for each member before they became a member?
with all_join as
	(select s.*, m.product_name, m.price 
	from sales s
	join menu m
	on s.product_id = m.product_id
    join members mem 
    on s.customer_id = mem.customer_id
    where s.order_date < mem.join_date
    )
select  customer_id, count(product_name) as items_ordered_before_membership, sum(price) as amount_spent_before_membership
from all_join
group by customer_id
order by customer_id;


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with all_join as
	(select s.*, m.product_name, m.price 
	from sales s
	join menu m
	on s.product_id = m.product_id
    join members mem 
    on s.customer_id = mem.customer_id
    )
select customer_id, sum(points) as total_points
from 
	(select  *, 
		case when product_name='sushi' then price*10*2
		else price*10
		end as points
	from all_join) x
group by customer_id
order by customer_id;


/* In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi. 
 how many points do customer A and B have at the end of January? */
 with all_join as
	(select s.*, m.product_name, m.price, mem.join_date, s.order_date - mem.join_date as days_after_joining 
	from sales s
	join menu m
	on s.product_id = m.product_id
    join members mem 
    on s.customer_id = mem.customer_id
    where s.order_date <= '2021-01-31'		-- code for end of jan
    )
select customer_id, sum(points) as points_at_end_of_jan
from 
	(select  *, 
		case when product_name='sushi' or days_after_joining between 0 and 6 then price*10*2		-- or condition added for first week after joining
		else price*10
		end as points
	from all_join) x
group by customer_id
order by customer_id;
