--dealerID here
declare @dealerid int = 117390

--pricing examples for new inventory
select top 3 stockno, vin, cost, invoiceprice, pricemsrp
from DealerSite..inventory
where dealerid = @dealerid
and listingtypeid = 1
and inventorystatusid = 1
and isnull(cost, 0.00) != 0.00
and isnull(invoicePrice, 0.00) != 0.00
and isnull(priceMSRP, 0.00) != 0.00
order by add_date desc

--pricing examples for used inventory
select top 3 stockno, vin, cost
from DealerSite..inventory
where dealerid = @dealerid
and listingtypeid = 2
and inventorystatusid = 1
and isnull(cost, 0.00) != 0.00
order by add_date desc

--count of all active vehicles by new/used
select 
	case when listingtypeid = 1 then 'New' else 'Used' end as 'all vehicles',
	count(vin) as 'count'
from dealersite..inventory
where dealerid = @dealerid 
and inventorystatusid = 1
group by listingtypeid
order by listingtypeid

--count of all active vehicles
select count(vin) as 'all active'
from DealerSite..inventory
where DealerID = @dealerid
and inventorystatusid = 1

--count of all active off hold vehicles by new/used
select 
	case when listingtypeid = 1 then 'New' else 'Used' end as 'off hold',
	count(vin) as 'count'
from dealersite..inventory
where dealerid = @dealerid 
and inventorystatusid = 1
and DoNotExport = 0
group by listingtypeid
order by listingtypeid

--count of all active off hold vehicles
select count(vin) as 'all off hold'
from DealerSite..inventory
where DealerID = @dealerid
and inventorystatusid = 1
and DoNotExport = 0

--count of new/used vehicles seen online
select case when listingtypeid = 1 then 'New' else 'Used' end as 'online',
	count(vin) as 'count'
from inventory..listing
where dealerid = @dealerid
and listingstatusid = 1
group by ListingTypeID
order by ListingTypeID 

--total count of online inventory
select count(vin) as 'all online'
from inventory..listing
where dealerid = @dealerid
and listingstatusid = 1

select si.ImportName, sid.FileName, sid.AutoOffHold, sid.NewAutoOffHold, sid.UsedAutoOffHold
from Integration..source_import_dealer sid
left join Integration..source_import si on si.ImportProcessorID = sid.ImportProcessorID
where sid.DealerID = @dealerid
and ImportTypeID = 1