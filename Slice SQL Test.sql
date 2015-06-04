/*
Slice SQL Test

Questions
Some questions have missing specifics.  Make some assumptions.
1.	Write syntax for left join, right join, inner join, outer join between table1 and table2. Define what each is doing.
2.	Count occurrence/frequency of distinct values in table1, column itemID.
3.	Produce all rows from table1 where the values in column itemDescription contain "LLC".
4.	Create a new table3 using table1 columns: itemID, date,  itemDescription and table2 columns orderTotal where orderTotal  is greater than 23.95.
5.	Update table1 with a new column called extPrice, which is the product of columns  quantity and price.
6.	Update all rows in table1, replacing records where itemDescription has a "%$" with a ":"
7.	What does a COMMIT do?
8.	What is a primary key, a foreign key?
9.	Give example of Boolean values.
10.	Select all rows from table1 between the dates of Oct 1, 2012 and Dec 31, 2013.
11.	From the two tables, give the sum of orderTotals by Merchant.
12.	Find all values in table1 itemDescription where there are any of the following expressions present singularly or in combination: "baby", "diaper", "wipes", "clean", "pull-ups".
13.	What are some techniques to obfuscate personally identifiable information?
14.	Write a query to get the data to answer the question: “are amazon.com and/or radioshack.com loosing or gaining iPhone 5c market share?”
15.	What date had the most sales by total dollars.

Note
Queries written for SQL Server 2012
*/





-----[1] Write syntax for left join, right join, inner join, outer join between table1 and table2. Define what each is doing.
select
distinct
t1.orderid,
t2.orderid,
t2.ordertotal

from table1 as t1

inner join table2 as t2		--replace "inner join" with "left join", "right join", and "full outer join" for each subsequent part of the question
on t2.orderid=t1.orderid

/*
inner join: for each orderid that appears in both table1 and table2, returns orderid (produced once from each table) and t2.ordertotal.
left join: returns all records from inner join. in addition, returns orderids that only appear in table1 (with fields from table2 set to NULL)
right join: returns all records from inner join. in addition, returns t2.orderid and t2.ordertotal for ids that only appear in table2 (with t1.orderid set to NULL)
full outer join: returns all records from inner join, left join, and right joins.
*/





-----[2] Count occurrence/frequency of distinct values in table1, column itemID. 
select
count(distinct itemid) as ct_distinct_itemids

from table1





-----[3] Produce all rows from table1 where the values in column itemDescription contain "LLC".
select *

from table1

where
lower(itemdescription) like '%llc%'		--assumes column is case sensitive





-----[4] Create a new table3 using table1 columns: itemID, date,  itemDescription and table2 columns orderTotal where orderTotal  is greater than 23.95.
if object_id('tempdb..#table3') is not null drop table #table3

select
t1.itemid,
t1.date,
t1.itemdescription,
t2.ordertotal

into #table3		--decided to use a temp table because it seems like this table is for a report and doesn't need to persist in the database

from table1 as t1

inner join table2 as t2
on t2.orderid=t1.orderid

where t2.ordertotal>23.95





-----[5] Update table1 with a new column called extPrice, which is the product of columns  quantity and price.
alter table table1
add extprice as (quantity*price) persisted





-----[6] Update all rows in table1, replacing records where itemDescription has a "%$" with a ":"
update table1
set itemdescription=replace(itemdescription,'%$',':')





-----[7] What does a COMMIT do?
/*
if the transaction count is greater than 0, reduces transaction count by 1.
if transaction count is then 0, makes all parts of the transaction permanent in the database and frees associated resources
*/





-----[8] What is a primary key, a foreign key?
/*
a primary key is a column (or set of columns) that uniquely identifies records in a table
a foreign key is a column (or set of columns) in one table that is a primary key in another table
*/





-----[9] Give example of Boolean values.
/*
1 if it is raining
0 if not
*/





-----[10] Select all rows from table1 between the dates of Oct 1, 2012 and Dec 31, 2013.
select *

from table1

where
date>='20121001'		--assumes date range in question was inclusive
and date<'20140101'





-----[11] From the two tables, give the sum of orderTotals by Merchant.
---[11a] map merchantid onto orderid (and remove duplicates)
if object_id('tempdb..#merchant_order_map') is not null drop table #merchant_order_map

select distinct
t1.merchantid,
t2.orderid,
t2.ordertotal

into #merchant_order_map

from table2 as t2

inner join table1 as t1
on t1.orderid=t2.orderid



---[11b] sum ordertotals by merchant
select
merchantid,
sum(ordertotal)

from #merchant_order_map

group by
merchantid





-----[12] Find all values in table1 itemDescription where there are any of the following expressions present singularly or in combination: "baby", "diaper", "wipes", "clean", "pull-ups".
select distinct
itemdescription

from table1

where
lower(itemdescription) like '%baby%'			--assumes column is case sensitive
or lower(itemdescription) like '%diaper%'
or lower(itemdescription) like '%wipes%'
or lower(itemdescription) like '%clean%'
or lower(itemdescription) like '%pull-ups%'





-----[13] What are some techniques to obfuscate personally identifiable information?
/*
1) if PII is a primary key, randomly generate a new primary key and delete or null PII
2) encryption
2) aggregation (when appropriate, mostly for reporting)
*/





----[14] Write a query to get the data to answer the question: “are amazon.com and/or radioshack.com loosing or gaining iPhone 5c market share?”
---[14a] find the total amount of money spent on iphones each day across the market as a whole
if object_id('tempdb..#market_sales_by_date') is not null drop table #market_sales_by_date

select
date,
sum(price*quantity) as market_sales_by_date

into #market_sales_by_date

from table1

where
productid='iPhone 5c'		--'iPhone 5c' is a placeholder productid
group by
date



---[14b] determine daily market share by merchant
select
t1.merchantid,
t1.date,
sum(t1.price*t1.quantity) as merchant_sales_by_date,
m.market_sales_by_date,
sum(t1.price*t1.quantity)/m.market_sales_by_date as daily_market_share

from table1 as t1

right join #market_sales_by_date as m
on m.date=t1.date

where
t1.merchantid in ('Amazon','Apple')		--'Amazon' and 'Apple' are placeholder merchantids
and t1.productid='iPhone 5c'			--'iPhone 5c' is a placeholder productid

group by
t1.merchantid,
t1.date,
m.market_sales_by_date

order by
t1.merchantid,
t1.date





-----[15] What date had the most sales by total dollars.
select
date,
sum(ordertotal)

from table2

group by
date

order by
sum(ordertotal) desc