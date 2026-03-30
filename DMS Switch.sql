--dealerID here
declare @dealerid int = 37735

--currently updatable fields and mappings for those fields
select si.ImportName, 
	d.Description, 
	id.col, 
	case when sidm.MappingTypeID = 1 then 'Transform' 
		when sidm.MappingTypeID = 2 then 'Filter' 
		when sidm.MappingTypeID = 3 then 'Validate' 
		when sidm.mappingtypeid = 4 then 'Conditional Update' 
		else '~~ no mapping set ~~' end as 'Mapping Type', 
	case when sidm.SQL = 'd.listingtypeid = 1' then '~~ updating new only ~~' 
		when sidm.sql = 'd.listingtypeid = 2' then '~~ updating used only ~~' 
		when sidm.sql is null then '~~ no mapping set ~~' 
		else sidm.SQL end as SQL
from integration..import_dealercolmap id
left join Integration..datacol d on id.DataColID = d.DataColID
left join Integration..source_import si on si.ImportProcessorID = id.ImportProcessorID
left join Integration..Source_Import_Dealer sid on sid.DealerID = id.DealerID and sid.ImportProcessorID = si.ImportProcessorID
left join Integration..ImportSourceDealerColumns i on i.ImportDealerID = sid.ImportDealerID and i.DataColID = d.DataColID
left join integration..source_import_dealer_mapping sidm on sid.dealerid = sidm.DealerID and sid.ImportProcessorID = sidm.ImportProcessorID and sidm.DataColID = id.DataColID
where id.DealerID = @dealerid
and sid.ImportTypeID = 1
and i.Updateable = 1
order by si.ImportName, d.Description

--pricing examples for new inventory
select top 3 stockno, vin, cost, invoiceprice, pricemsrp
from DealerSite..inventory
where dealerid = @dealerid
and listingtypeid = 1
and inventorystatusid = 1
and (isnull(cost, 0.00) != 0.00
or isnull(invoicePrice, 0.00) != 0.00
or isnull(priceMSRP, 0.00) != 0.00)
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