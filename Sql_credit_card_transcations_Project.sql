Select * from credit_card_transcations;
Alter table credit_card_transcations
alter column amount  BIGINT;
----------------------
--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

Select top 5 city, sum(amount) as sales,Round(100.0*sum(amount)/sum(sum(amount)) over(),2) as total_sales_Percentage from credit_card_transcations
group by city
order by sales desc;
-----------------
--write a query to print highest spend month and amount spent in that month for each card type

with cte as (
Select card_type,DATEPART(Month,transaction_date) as mt,DATEPART(Year,transaction_date) as yt,
sum(amount) as sales from credit_card_transcations
group  by card_type,DATEPART(Month,transaction_date) ,DATEPART(Year,transaction_date)
)
Select * from (select *,ROW_NUMBER () Over (partition by card_type order by sales desc) as rn  from cte) a
where rn = 1;

---------------------
--write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
Select *,sum(amount) over (partition by card_type order by transaction_date,transaction_id ) as running_sales from credit_card_transcations
),
cte2 as( 
select *,ROW_NUMBER () over(partition by card_type order by running_sales) as rn from cte 
where running_sales>1000000)
select * from cte2
where rn =1;

-----------------

--write a query to find city which had lowest percentage spend for gold card type

with cte as (Select city,card_type,sum(amount) as sale,100.0*sum(amount)/sum(sum(amount))over(partition by city) as sales from credit_card_transcations
group by city,card_type),
cte2 as (select *,ROW_NUMBER() over (order by sales asc) as rn from cte where card_type='Gold' and sales>0)
select * from cte2 
where rn=1
;
---------------------------------
--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (Select city,exp_type,sum(amount) as sale,ROW_NUMBER() over (partition by city order by sum(amount)) as rnasc, 
ROW_NUMBER() over (partition by city order by sum(amount) desc) as rndesc from credit_card_transcations
group by city,exp_type
)
select city,max(case when rnasc=1 then exp_type end) as lowest_expense_type,
max(case when rndesc=1 then exp_type end) as highest_expense_type  from cte
group by city
;
------------------------------
--write a query to find percentage contribution of spends by females for each expense type
with cte as (Select exp_type,gender,sum(amount) as exp,
100.0*sum(amount)/sum(sum(amount))over (partition by exp_type) as percentage_exp_type_amt from credit_card_transcations
group by exp_type,gender)
select * from cte 
where gender='F'
order by percentage_exp_type_amt desc
;

----------------------------------
--which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (Select card_type,exp_type,format(transaction_date,'MMM-yyy') as my,EOMONTH(transaction_date) as mnth,sum(amount) as expense 
from credit_card_transcations
group by card_type,exp_type,format(transaction_date,'MMM-yyy'),EOMONTH(transaction_date)),
cte2 as (select *,lag(expense) over (partition by card_type,exp_type order by mnth asc) as previous_sale,
expense-lag(expense) over (partition by card_type,exp_type order by mnth asc) as growth_from_previous_month_sale from cte)
select top 1 * from cte2 
where my='Jan-2014'
order by growth_from_previous_month_sale desc
;
--------------------------
--during weekends which city has highest total spend to total no of transcations ratio 
with cte as (select *,DATEName(WEEKDAY,transaction_date) as weekdayname
from credit_card_transcations
where DATEName(WEEKDAY,transaction_date) in ('Saturday','Sunday'))
select top 1 city,sum(amount)/count(amount) as ratio from cte
group by city
order by sum(amount)/count(amount) desc
;
------------------------------
--which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (Select *,ROW_NUMBER() over (partition by city order by transaction_date,transaction_id) as transaction_number from credit_card_transcations),
cte2 as (select *,lag(transaction_date) over (partition by city order by transaction_date) as start_date from cte
where transaction_number in (1,500))
Select top 1*,DATEDIFF(day,start_date,transaction_date) as dateinterval from cte2
where start_date is not null
order by DATEDIFF(day,start_date,transaction_date)
;


























