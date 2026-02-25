--import feed details

--dealer ID here
declare @dealerid int = 

--fgls queries

--selects settings on all imports configured on that ID
select si.importname, 
	case when sid.filename is null then '~~ no file selected ~~' else sid.FileName end as Filename, 
	case when sid.ImportTypeID = 1 then 
		case 
			when sid.AutoOffHold = 1 then 'Enabled' 
			when sid.AutoOffHold = 0 and sid.NewAutoOffHold = 1 then 'New Only' 
			when sid.AutoOffHold = 0 and sid.UsedAutoOffHold = 1 then 'Used Only' 
			else 'Disabled' end 
		else '' end as AutoOffHold, 
	case when sid.importtypeid = 1 then 'DMS' 
		when sid.importtypeid = 2 then 'Website' 
		when sid.importtypeid = 3 then 'Photos' 
		when sid.importtypeid = 4 then 'IM' 
		when sid.importtypeid = 5 then 'Sold' 
		else '~~ no type set ~~' end as 'Import Type',
	case when sid.keepPhotos = 1 and i.Updateable = 1 then 'keep manual photos'
		when sid.keepPhotos = 0 and i.Updateable  = 1 then 'delete manual photos' 
		else ' ' end as 'keep manual photos',
	case when i.Updateable = 1 and sid.ImportIfNoExistingPhotos = 1 then 'only import if no photos'
		when i.Updateable = 1 and sid.ImportIfNoExistingPhotos = 0 then 'overwrite all photos'
		else ' ' end as 'import if no photos'
from integration..source_import_dealer sid
left join Integration..source_import si on si.ImportProcessorID = sid.ImportProcessorID
left join Integration..ImportSourceDealerColumns i on i.ImportDealerID = sid.ImportDealerID and i.DataColID = 48
where sid.DealerID = @dealerid
order by sid.ImportTypeID

--selects the fields that are mapped and marked updatable from the fields we would typically need to update during a go live
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
and d.Description in ('wholesaleind', 'certifiedind', 'description', 'photourl', 'pricemsrp', 'price', 'lotprice', 'cost', 'invoiceprice', 'donotexport')
and i.Updateable = 1
order by sid.ImportTypeID, d.Description

--percentage(new off hold / total new)
--percentage(used off hold / total used)
--total new 
--total new off hold
--total used
--total used off hold

declare @newHold float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and DoNotExport = 0
and InventoryStatusId = 1)
declare @newInventory float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and InventoryStatusId = 1)
declare @usedHold float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 2
and DoNotExport = 0
and InventoryStatusId = 1)
declare @usedInventory float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 2
and InventoryStatusId = 1)

select @newHold as 'new off hold', @newInventory as 'total new', case when @newInventory != 0 then round((@newHold / @newInventory) * 100, 0) else 0 end as 'new off hold %'
select @usedHold as 'used off hold', @usedInventory as 'total used', case when @usedInventory != 0 then round((@usedHold / @usedInventory) * 100, 0) else 0 end as 'used off hold %'

--percentage(count(new no msrp)/count(total new))
--percentage(count(new no invoice)/count(total new))
--percentage(count(new no cost)/count(total new))

declare @newNoMSRP float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and isnull(priceMSRP, 0.00) = 0.00
and InventoryStatusId = 1)
declare @newNoInvoice float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and isnull(InvoicePrice, 0.00) = 0.00
and InventoryStatusId = 1)
declare @newNoCost float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and isnull(Cost, 0.00) = 0.00
and InventoryStatusId = 1)
declare @newNoLotPrice float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and isnull(LotPrice, 0.00) = 0.00
and InventoryStatusId = 1)
declare @newNoPrice float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 1
and isnull(Price, 0.00) = 0.00
and InventoryStatusId = 1)

select 
	case when @newInventory != 0 then round((@newNoMSRP / @newInventory) * 100, 0) else 0 end as 'new no MSRP %',
	case when @newInventory != 0 then round((@newNoInvoice / @newInventory) * 100, 0) else 0 end as 'new no invoice %',
	case when @newInventory != 0 then round((@newNoCost / @newInventory) * 100, 0) else 0 end as 'new no cost %',
	case when @newInventory != 0 then round((@newNoLotPrice / @newInventory) * 100, 0) else 0 end as 'new no lot price %',
	case when @newInventory != 0 then round((@newNoPrice / @newInventory) * 100, 0) else 0 end as 'new no price %'

--percentage(count(used no cost)/count(total used))
--percentage(count(used with invoice)/count(total used)

declare @usedNoCost float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 2
and isnull(Cost, 0.00) = 0.00
and InventoryStatusId = 1)
declare @usedInvoice float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 2
and isnull(InvoicePrice, 0.00) != 0.00
and InventoryStatusId = 1)
declare @usedNoPrice float = (select count(vin)
from DealerSite..inventory
where dealerid = @dealerid
and ListingTypeID = 2
and isnull(Price, 0.00) = 0.00
and InventoryStatusId = 1)

select 
	case when @usedInventory != 0 then round((@usedNoCost / @usedInventory) * 100, 0) else 0 end as 'used no cost %',
	case when @usedInventory != 0 then round((@usedInvoice / @usedInventory) * 100, 0) else 0 end as 'used with invoice %',
	case when @usedInventory != 0 then round((@usedNoPrice / @usedInventory) * 100, 0) else 0 end as 'used no price %'

--average photo count for new
--average photo count for used
--count new with no photos
--count used with no photos

declare @newPhotos float = (select count(ip.photourl)
from DealerSite..inventory i
left join DealerSite..InventoryPhoto ip on ip.InventoryID = i.InventoryID
where i.dealerid = @dealerid
and i.ListingTypeID = 1
and i.InventoryStatusId = 1)

declare @newWithPhotos int = @newInventory - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 1
	and ip.InventoryID is null)

declare @usedWithPhotos int = @usedInventory - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 2
	and ip.InventoryID is null)

select case when @newWithPhotos != 0 then round(@newPhotos / @newWithPhotos, 0) else 0 end as 'avg new photo count'

declare @usedPhotos float = (select count(ip.photourl)
from DealerSite..inventory i
left join DealerSite..InventoryPhoto ip on ip.InventoryID = i.InventoryID
where i.dealerid = @dealerid
and i.ListingTypeID = 2
and i.InventoryStatusId = 1)

select case when @usedWithPhotos = 0 then 0 when @usedInventory != 0 then round(@usedphotos / @usedWithPhotos, 0) else 0 end as 'avg used photo count'

select count(i.vin) as 'new count no photos', case when @newInventory != 0 then round((count(i.vin) / @newInventory) * 100, 0) else 0 end as 'new no photo %'
from dealersite..inventory i 
left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
where i.dealerid = @dealerid
and i.ListingTypeID = 1
and i.InventoryStatusId = 1
and ip.InventoryID is null

select count(i.vin) as 'used count no photos', case when @usedInventory != 0 then round((count(i.vin) / @usedInventory) * 100, 0) else 0 end as 'used no photo %'
from dealersite..inventory i 
left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
where i.dealerid = @dealerid
and i.ListingTypeID = 2
and i.InventoryStatusId = 1
and ip.InventoryID is null