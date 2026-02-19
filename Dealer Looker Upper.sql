declare @dlrname as varchar(40) = ''
declare @dlrname2 as varchar(40) = 'dfadfasf'
declare @dealerid as int = 999999
declare @postalcode as varchar(5)='04092'
declare @city as varchar(20)=''
declare @state as varchar(2)=''
declare @websitecompanies as table(webco varchar(20)) 

INSERT INTO @websitecompanies
VALUES
	('VinAudit'),
	('')

--select * from @websitecompanies
--select @dlrname, @dlrname2, @dealerid, @postalcode, @city, @state

select d.dealerid
	, case when clientind=1 then 'C' else '' end as C
	, ds.status
	, d.dealername + ' (' + cast(d.dealerid as varchar) + ')' dealernameid
	, isnull((select cmks.makes from
		(
		select dmks.dealerid
			, '[' + string_agg(convert(nvarchar(max), dmks.makename), '] [') within group (order by dmks.makename asc) + ']' as makes
		from (select dm.dealerid
					, mk.makename
				from dealermake dm with(nolock)
					join make mk with(nolock) on dm.makeid=mk.makeid
				) AS dmks
		group by dmks.dealerid
		) AS cmks
		where cmks.dealerid=d.dealerid),'') as franchises
	, d.address
	, d.city
	, d.state
	, d.postalcode
	, d.mainurl
	, d.dealername
	, d.mainphone
	, d.websitecompany
	, d.srplocation
	, isnull(dn.notes,'') notes
from dealer d with (nolock)
	join dealerstatus ds with (nolock) on d.dealerstatusid=ds.dealerstatusid
	left join dealernote dn with (nolock) on d.dealerid=dn.dealerid
where (d.dealername like '%' + @dlrname + '%'
		or d.dealername like '%' + @dlrname2 +'%'
		or d.mainurl like '%' + @dlrname + '%'
		or d.mainurl like '%' + @dlrname2 + '%'
		or d.dealerid=@dealerid)
	and d.postalcode like @postalcode + '%'
	and d.city like '%' + @city + '%'
	and d.[state] like '%' + @state + '%'
--	and d.websitecompany in(select webco from @websitecompanies)
	--and (d.websitecompany in(select webco from @websitecompanies)
	--	or len(rtrim(isnull(d.websitecompany,'')))=0)
	and d.dealerstatusid in(1,5)
group by
	d.dealerid
	, case when clientind=1 then 'C' else '' end
	, ds.status
	, d.dealername
	, d.dealername + ' (' + cast(d.dealerid as varchar) + ')'
	, d.address
	, d.city
	, d.state
	, d.postalcode
	, d.mainurl
	, d.mainphone
	, d.websitecompany
	, d.srplocation
	, isnull(dn.notes,'')
order by d.address, d.dealername, d.postalcode