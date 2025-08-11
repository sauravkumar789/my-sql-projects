Select * from athlete_events;
Select * from athletes;

---1 which team has won the maximum gold medals over the years.

Select top 1 team,medal,count(event) as no_of_gold_medal from athlete_events e join athletes a
on e.athlete_id=a.id
where medal='Gold'
group by team,medal
order by no_of_gold_medal desc;

-----2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
with cte as (Select team,year,medal,count(distinct event) as no_of_silver_medal,ROW_NUMBER()over(partition by team order by count(*) desc) as rn 
from athlete_events e join athletes a
on e.athlete_id=a.id
where medal='Silver'
group by team,year,medal)
Select team,sum(no_of_silver_medal) as total_silver_medal,max(case when rn=1 then year else 0 end) as year_of_max_silver from cte
group  by team;
;
-----3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years

Select top 1 name,medal,count(*) as no_of_medal 
from athlete_events e join athletes a
on e.athlete_id=a.id
where name not in (
select name from athlete_events e join athletes a
on e.athlete_id=a.id
where medal='silver' or medal='Bronze' or medal='na')
group by name,medal
order by no_of_medal desc;

----4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.


with cte as (Select name,year,medal,count(*) as no_of_gold_medal,dense_rank()over(partition by year order by count(*) desc) as rn 
from athlete_events e join athletes a
on e.athlete_id=a.id
Where medal = 'Gold'
group by name,year,medal
)
Select year,no_of_gold_medal,string_agg(name,' , ') within group (order by name) as top_gold_medalist from cte
where rn = 1
group by year,no_of_gold_medal
order by year;

----5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

with cte as (Select team,year,event,medal,rank()over(partition by medal order by year) as rn 
from athlete_events e join athletes a
on e.athlete_id=a.id
where team='India' and medal!='NA')
Select medal,year,event from cte where rn=1
group by medal,year,event
;
----6 find players who won gold medal in summer and winter olympics both.
with cte as (Select name,season from athlete_events e join athletes a
on e.athlete_id=a.id
where medal ='Gold')
Select name,count(distinct season) from cte
group by name
having count(distinct season)=2
;

----7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
Select name,year from athlete_events e join athletes a
on e.athlete_id=a.id
where medal in ('Gold','Silver','Bronze')
group by name,year
having count(distinct medal)=3
;

----8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.


with cte as (Select name,year,event from athlete_events e join athletes a
on e.athlete_id=a.id
where year>=2000 and season ='Summer' and medal='Gold'
group by name, year,event)
Select * from 
(select *,lag(year,1) over (partition by name,event order by year) as prev_year,
lead(year,1) over (partition by name,event order by year) as next_year 
from cte) a
where year=prev_year+4 and year=next_year-4;










