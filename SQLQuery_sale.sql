---Inspecting Data
select * from [dbo].[sales_data_sample]

--CHecking unique values ---> distinct stop duplicate 
select distinct status from [dbo].[sales_data_sample] --Nice one to plot in tableau
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---Nice one to plot in tableau
select distinct COUNTRY from [dbo].[sales_data_sample] ---Nice one to plot in tableau
select distinct DEALSIZE from [dbo].[sales_data_sample] ---Nice one to plot in tableau
select distinct TERRITORY from [dbo].[sales_data_sample] ---Nice one to plot in tableau


---- from exploring the data we can see that the data set of 2005 only contain 5 month of sale activity compare to 
----2003 and 2004


select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2003

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2004

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2005


---ANALYSIS
----Let's start by grouping sales by productline

select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by Revenue desc

---- by grouping sales by Year
select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select  DEALSIZE,  sum(sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc


----What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [PortfolioDB].[dbo].[sales_data_sample]
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by 2 desc



--November seems to be the month, what product do they sell in November, Classic I believe
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from [PortfolioDB].[dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc



----Who is our best customer (this could be best answered with RFM)
----Recency-frequency-monetary
---- it is an indexing techiquethat uses past purchase  behavior to segment customers
----- An rfm report is a way of segmentingcustomers using three key metric:
------ recency(how long ago their last purchase was)
------frequency(How often they purchase)
------monetary vaue(how much they spent)

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,--- when the customer made their last order
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,---- get the max date 
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency --- last order date - max date 
	from [PortfolioDB].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(
---- NTILE() function in SQL Server is a window function that distributes rows of an ordered partition into a pre-defined number of roughly equal group
	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,---- The closer the last order is to the max date the higher the rfm_recency
		NTILE(4) OVER (order by Frequency) rfm_frequency,---- The higher the volume the higher the rfm_frequency
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary--- The bigger the sale value the higher the rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string --- converting the int to string in a new cell as rfm cell
into #rfm
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

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [PortfolioDB].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc


---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc