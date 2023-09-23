--What is the total amount each customer spent at the restaurant?
select 
	s.customer_id, 
	sum(price) as total_amount_spent
from sales s 
	join menu me on s.product_id = me.product_id
group by customer_id

--How many days has each customer visited the restaurant?
select
	customer_id, 
	count(Distinct order_date) as total_days_visited
from sales
group by customer_id

--What was the first item from the menu purchased by each customer?

with cte as(
select 
	customer_id,
	s.order_date,
	m.product_name,
	Rank() over (partition by customer_id  order by order_date) as Rank_of_products
from sales s
	join menu m on s.product_id = m.product_id)

select * 
from cte
	where Rank_of_products = 1

--What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1
	m.product_name,
	count(s.product_id) as orders
from sales s
	join menu m on s.product_id= m.product_id
group by m.product_name
order by orders desc
	
	
--Which item was the most popular for each customer?
with cte as(
select 
	m.product_name,
	customer_id,
	count(s.product_id) as orders,
	RANK()over(PARTITION BY customer_id order by count(s.product_id) desc) as rnk
from sales s
	join menu m on s.product_id= m.product_id
group by customer_id,product_name)
select 
	customer_id,
	product_name
from cte
where rnk = 1
	
--Which item was purchased first by the customer after they became a member?
with cte as(
SELECT
	s.customer_id,
	s.product_id,
	mn.product_name,
	s.order_date,
	m.join_date,
	rank()over(partition by s.customer_id order by order_date) as rnk
from sales s
	join members m on s.customer_id = m.customer_id
	join menu mn on s.product_id = mn.product_id
where order_date >= join_date)

select 
	customer_id,
	product_name,
	rnk
from cte
where rnk = 1
	
--Which item was purchased just before the customer became a member?
with cte as(
SELECT
	s.customer_id,
	s.product_id,
	mn.product_name,
	s.order_date,
	m.join_date,
	rank()over(partition by s.customer_id order by order_date desc) as rnk
from sales s
	join members m on s.customer_id = m.customer_id
	join menu mn on s.product_id = mn.product_id
where order_date < join_date)

select 
	customer_id,
	product_name,
	order_date,
	rnk
from cte
where rnk = 1
--What is the total items and amount spent for each member before they became a member?
SELECT
	s.customer_id,
	sum(price) as total_amount,
	count(s.product_id) as total_items
from sales s
	join menu mn on s.product_id = mn.product_id
	join members m on s.customer_id = m.customer_id
where order_date < join_date
group by s.customer_id
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
	customer_id,
	sum(
	case 
	when product_name = 'sushi' then price*10*2
	else price*10
	end )as points
from menu mn
	join sales s on mn.product_id= s.product_id
group by customer_id

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select 
	s.customer_id,
	sum(case
		when order_date between m.join_date AND	DATEADD(day,6,m.join_date) then price *10*2
		when product_name = 'sushi' then price*10*2
		else price*10
	end) as points
from menu mn
	join  sales s on s.product_id = mn.product_id
	join members m on m.customer_id = s.customer_id
where DATETRUNC (month,order_date) = '2021-01-01'
group by s.customer_id

--Retrieve records for each customer showing whether they were a member or not for each order they did.

select 
	s.customer_id,
	order_date,
	product_name,
	price,
	case
		when join_date > order_date then 'N'
		 when join_date <= order_date then 'Y'
		 when join_date is null then 'N'
	end as member
from sales s
	join menu mn on s.product_id = mn.product_id
	left join members m on s.customer_id = m.customer_id
order by customer_id, order_date



---Rank the records from the query above by the order date
with cte as(
select 
	s.customer_id,
	order_date,
	join_date,
	product_name,
	price,
	case
		when join_date > order_date then 'N'
		 when join_date <= order_date then 'Y'
		 when join_date is null then 'N'
	end as member, 
	case 
		when join_date is null then NULL
		when order_date< join_date then NULL
		else rank()over(partition by s.customer_id,(
			case
				when join_date > order_date then 'N'
				when join_date <= order_date then 'Y'
				when join_date is null then 'N'
			end) 
		order by order_date)
		end as ranking
from sales s
	join menu mn on s.product_id = mn.product_id
	left join members m on s.customer_id = m.customer_id)

select * 
from cte 

