Select * from adidas_sales;
Select * from adidas_sales
order by invoice_date asc;
Describe adidas_sales;
Select distinct sales_method from adidas_sales;
Select distinct product from adidas_sales;
Select distinct retailer from adidas_sales;
Select distinct retailer_id from adidas_sales;
-- There are 6 retailers but only 4 retailer ids

Select distinct retailer, retailer_id from adidas_sales;
Select retailer,
       count(distinct retailer_id) as id_count
from adidas_sales
group by retailer
having count(distinct retailer_id) > 1;
-- Either there's an error or retailer id means the supplier (probably not).
-- As a result, retailer_id was excluded from analytical grouping, and the retailer field was used as the primary retailer dimension


-- 1) Calculating which regions are most profitable
Select region, (sum(operating_profit)/sum(total_sales)) * 100 as profit_margin
from adidas_sales
group by region
order by profit_margin desc;

-- 2) Calculating which states are most profitable
Select state, (sum(operating_profit)/sum(total_sales)) * 100 as profit_margin
from adidas_sales
group by state
order by profit_margin desc;

Select region, state, (sum(operating_profit)/sum(total_sales)) * 100 as profit_margin
from adidas_sales
group by region, state
order by profit_margin desc;

-- 3) Determining which sales method is the most effective
Select sales_method, sum(units_sold) as total_units_sold, sum(operating_profit) as total_operating_profit
from adidas_sales
group by sales_method
order by total_units_sold desc;

-- 4) Determining which sales method is the most profitable per unit
Select sales_method, 
	round(avg(price_per_unit), 2) as average_price_per_unit,
    round(avg(operating_profit), 2) as average_operating_profit,
    count(*) as transaction_count,
    round((sum(operating_profit)/sum(units_sold)), 2) as profit_per_unit
from adidas_sales
group by sales_method
order by profit_per_unit desc;

-- 5) Finding which cities are falling behind on sales
With 
city_sales as (
	select state, city, sum(total_sales) as city_sales
    from adidas_sales
    group by state, city
),
state_average_sales as (
	select state, round(avg(city_sales), 2) as state_average_sales
    from city_sales
    group by state
)

-- select * from city_sales;
-- select * from state_average_sales;

Select
	cs.state, cs.city, cs.city_sales, sa.state_average_sales
from city_sales cs
join state_average_sales sa
	on cs.state = sa.state
where cs.city_sales < sa.state_average_sales;

-- 6) Monthly sales analysis
With monthly_sales as (
    Select
        extract(YEAR from invoice_date) as sales_year,
        extract(MONTH from invoice_date) as sales_month,
        sum(total_sales) as monthly_sales
    from adidas_sales
    group by
        extract(YEAR from invoice_date),
        extract(MONTH from invoice_date)
)
Select
    sales_year,
    sales_month,
    monthly_sales,
    lag(monthly_sales) over (
        order by sales_year, sales_month
    ) as previous_month_sales,
    round(
        (monthly_sales - lag(monthly_sales) over (
            order by sales_year, sales_month
        )) 
        / lag(monthly_sales) over (
            order by sales_year, sales_month) * 100, 2) AS percent_change
from monthly_sales
order by sales_year, sales_month;
