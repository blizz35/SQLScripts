declare @dealerid int = --DEALERID HERE, @months int = 2
	
declare @date date

	SELECT @date = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - @months, 0)
	
	select YEAR(add_date) AS Year,
		   MONTH(add_date) AS Month, count(1) as inboundCount
	from dealersite..leadform
	where dealerid = @dealerid
	and add_date > @date
	and leadformtypeid = 12016
	and referer not like '%ico%'
	GROUP BY YEAR(add_date), MONTH(add_date)
	ORDER BY Year, Month;

	select YEAR(add_date) AS Year,
		   MONTH(add_date) AS Month, count(1) as ICOCount
	from dealersite..leadform
	where dealerid = @dealerid
	and add_date > @date
	and leadformtypeid = 12016
	and referer  like '%ico%'
	GROUP BY YEAR(add_date), MONTH(add_date)
	ORDER BY Year, Month;