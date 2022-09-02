---Inspecting Data
select * from [dbo].[sales_data_sample]

--Checking Unique values
select distinct status from [dbo].[sales_data_sample] 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] 
select distinct COUNTRY from [dbo].[sales_data_sample] 
select distinct DEALSIZE from [dbo].[sales_data_sample] 
select distinct TERRITORY from [dbo].[sales_data_sample] 

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2003

---ANALYSIS
----Let's start by grouping sales by productline
select PRODUCTLINE, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

--Checking which Year has max/min Sales

select YEAR_ID, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

--Checking which deal has max/min Sales
select  DEALSIZE,  sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc

--Checking Revenue in Each Country
select sum(sales) as Revenue,COUNTRY
from [dbo].[sales_data_sample]
group by COUNTRY
order by 1 desc




select sum(sales) as Revenue,COUNTRY,YEAR_ID,MONTH_ID
from [dbo].[sales_data_sample]
group by YEAR_ID,MONTH_ID,COUNTRY
order by 3 desc


----What was the best month for sales in a specific year? How much was earned that month? 

select  MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --change year to see the result for other years
group by  MONTH_ID
order by 2 desc


--November seems to be the month, but what product do they sell in November?
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc
-- Classic Cars is the most sold product in November


----Who is our best customer (Analysing by RFM method)


DROP TABLE IF EXISTS #rfm --check if already the temp table #rfm exists. If exists, drop it
;with rfm as 
(
	select CUSTOMERNAME, 
		sum(sales) as  MonetaryValue,
		avg(sales) as AvgMonetaryValue,
		count(ORDERNUMBER) as Frequency,
		max(ORDERDATE) as last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) as max_order_date,   --To know the max date in entire data set
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) as Recency  -- diff between the max date in entire data set & recent date (in terms of no. of days)
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(
select r.*,
		NTILE(4) OVER (order by Recency desc) as rfm_recency, -- if it is 4, they ordered very recently
		NTILE(4) OVER (order by Frequency) as rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) as rfm_monetary
from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell, -- it performs mathematical addition
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) as rfm_cell_string -- it performs concatenation by casting to string format
into #rfm -- #rfm is temp table
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

select distinct ORDERNUMBER, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) as rn
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER   -- Gives the count of products shipped/ordered with particular order no.
			)m
			where rn = 3  -- gives the orderno. in which 3 products are shipped together
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')) --converts column to rows where productcode separetd by ''

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc



--What city has the highest number of sales in a specific country
select city, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc


