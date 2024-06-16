drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;
==========================================================================
--1 what is the total amount each customer spent on zomato?
select 
	s.userid,
	sum(p.price) as total_amount
	from sales s join product p 
	on s.product_id=p.product_id
	group by s.userid
==========================================================================
--2 How many days each customer have visited zomato?
select 
	userid,
	count(distinct created_date) distinct_days 
	from sales
	group by userid
=========================================================================
--3 what was the first product purchased by each customer?
select * from
	(select * ,
		rank() over(partition by userid order by created_date) rnk 
		from sales)
	a where rnk=1
==============================================================================================
--4 what is the most purchased item on the menu and how many it was purchased by all customers?
select 
	top 1 product_id,
	count(product_id) as number_of_times_purchased 
	from sales 
	group by product_id 
	order by number_of_times_purchased desc
--to find which customer purchases how many times?
select userid,count(product_id) as cnt from sales where product_id in
(select 
	top 1 product_id 
	from sales 
	group by product_id 
	order by count(product_id) desc) group by userid
===========================================================================
--5 which item was most popular for each of the customer?
select 
	userid,product_id from
		(select *,rank() over(partition by userid order by cnt desc) rnk from
			(select userid,product_id,count(product_id)cnt from sales group by userid,product_id)a )b 
	where rnk=1
============================================================================
--6 which item was first purchased by the customer after they become a member?
select *from 
	(select *,rank() over(partition by userid order by created_Date) rnk from
		(select
		a.userid,
		a.created_date,
		a.product_id,
		b.gold_signup_date 
		from sales a inner join goldusers_signup b
		on a.userid=b.userid
		and created_date>=gold_signup_date)c )d
	where rnk=1
==============================================================================
--7 which was the item customer purchased just before becoming a member?
select * from
	(select *,rank() over (partition by userid order by created_date desc) rnk from
		(select
			a.userid,
			a.created_date,
			a.product_id,
			b.gold_signup_date 
			from sales a inner join goldusers_signup b
			on a.userid=b.userid and created_date<gold_signup_date)c
		) d
	where rnk=1
====================================================================================
--8 what is the total orders and amount spent for each member before they become a member?

select 
	userid,
	count(product_id) as total_number_of_orders,
	sum(price) as total_amount_spent from
	(select 
		c.userid,
		c.created_date,
		c.product_id,
		d.price from 
		(select a.userid,
			a.created_date,
			a.product_id,
			b.gold_signup_date from
			sales a inner join goldusers_signup b on a.userid=b.userid 
			and created_date<gold_signup_date)c
		inner join product d on c.product_id=d.product_id)e
	group by userid
===================================================================================
--9 If buying each product generates points for eg 5rs=2 zomato points and each product has different purchasing points for eg for p1 5rs=1 zomato point 
--for p2 10rs= 5 zomato points and for p3 5rs=1 zomato point 
--calculate points collected by each customer and for which product most points have been given till now.
 
 --first_part: points collected by each 
select 
	d.userid,
	sum(amount/points) as total_points_earned from
	(select c.*,
		case when product_id=1
				then 5 
			when product_id=2 
				then 2 
			when product_id=3 
				then 5 
			else 0  end  as points from
		(select 
			a.userid,
			a.product_id,
			sum(b.price ) as amount from 
			sales a inner join product b 
			on a.product_id=b.product_id 
			group by a.userid,a.product_id)c
		) d 
	group by d.userid
--second part:which product most points
	select * from
	(select *,rank() over ( order by total_points_earned desc) rnk from
	(select 
	d.product_id,
	sum(amount/points) as total_points_earned from
	(select c.*,
		case when product_id=1
				then 5 
			when product_id=2 
				then 2 
			when product_id=3 
				then 5 
			else 0  end  as points from
		(select 
			a.userid,
			a.product_id,
			sum(b.price ) as amount from 
			sales a inner join product b 
			on a.product_id=b.product_id 
			group by a.userid,a.product_id)c
		) d 
	group by d.product_id)e)f where rnk=1
================================================================================================
--10 In the first one year after a customer joins the gold program (including their joining date )irrespective of 
--what the customer has purchased they earn 5 zomato points for every 10rs spent who earned more 1 or 3 
--and what was their points earnings in their first yr

select c.*,
	(d.price)/2 from
	(select a.*,
		b.gold_signup_date 
		from sales a inner join goldusers_signup b
		 on a.userid=b.userid 
		and a.created_date >= b.gold_signup_date
		and created_date<DATEADD(year,1,gold_signup_date))c
	inner join product d 
	on c.product_id=d.product_id
==========================================================================================================================
--11 Rank all the transactions of the customer 

select *,rank() over(partition by userid order by created_date ) rnk from sales
=====================================================================================================================
--12 rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as na 
select *,
	case when rnk=0 
		then 'na'
	 else rnk end as rnkk from
	(select *,
		cast((case when gold_signup_date is Null then 0 else rank() over(partition by userid order by created_date desc ) end)as varchar) as rnk from
		(select a.*,
			b.gold_signup_date from 
			sales a left join goldusers_signup b 
			on a.userid=b.userid 
			and a.created_date >= b.gold_signup_date)c
	)d

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;