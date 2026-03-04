/**
* this is a set of unit tests to run after setting up the first round of imports for a dealership
* the tests check to see if the inventory has cost/invoice/MSRP, if the total count off hold matches the website, and if final price is close to the website
* if there is no new or used inventory, each test will say
* 
* enter dealer ID in @dealerid and run the full script
*
* @range can be adjusted if needed
*/

--dealer ID to check here
declare @dealerid int = 
--percentage range here
declare @range float = 10


/**
* variable block to set up counts
*/

declare @minusRange float = 100 - @range
declare @newActiveCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.donotexport = 0
	and i.listingtypeid = 1)
declare @usedActiveCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.donotexport = 0
	and i.listingtypeid = 2)
declare @newTotalCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.listingtypeid = 1)
declare @usedTotalCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.listingtypeid = 2)
declare @newNoCost float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Cost, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @usedNoCost float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Cost, 0.00) = 0.00
	and i.listingtypeid = 2)
declare @newNoMSRP float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.pricemsrp, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @newNoInvoice float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.InvoicePrice, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @newNoPrice float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Price, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @usedNoPrice float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Price, 0.00) = 0.00
	and i.listingtypeid = 2)
declare @newPhotos float = (select count(ip.photourl)
	from DealerSite..inventory i
	left join DealerSite..InventoryPhoto ip on ip.InventoryID = i.InventoryID
	where i.dealerid = @dealerid
	and i.ListingTypeID = 1
	and i.InventoryStatusId = 1)
declare @usedPhotos float = (select count(ip.photourl)
from DealerSite..inventory i
	left join DealerSite..InventoryPhoto ip on ip.InventoryID = i.InventoryID
	where i.dealerid = @dealerid
	and i.ListingTypeID = 2
	and i.InventoryStatusId = 1)
declare @newWithPhotos float = @newTotalCount - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 1
	and ip.InventoryID is null)
declare @newNoPhotos float = @newTotalCount - @newWithPhotos
declare @usedWithPhotos float = @usedTotalCount - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 2
	and ip.InventoryID is null)
declare @usedNoPhotos float = @usedTotalCount - @usedWithPhotos
drop table if exists #testCheckResults
create table #testCheckResults (test varchar(100), result varchar(100))

/**
* NEW INVENTORY
*/

--off hold count more than @range off of website crawling for new
insert into #testCheckResults
values ('new inventory count vs website',
(select case when @newTotalCount = 0 then 'no new inventory' when @newActiveCount = 0 then 'fail' else 
case when (abs(@newActiveCount)/count(l.vin))*100 between @range and (100 + @range) then 'pass' else 'fail' end end
from inventory..Listing l
where l.dealerid = @dealerID
and l.ListingStatusID = 1
and l.ListingTypeID = 1))

--select 'new inventory count vs website' as 'test',
--case when @newTotalCount = 0 then 'no new inventory' when @newActiveCount = 0 then 'fail' else 
--case when (abs(@newActiveCount-count(l.vin))/count(l.vin))*100 between @range and (100 + @range) then 'pass' else 'fail' end end as 'result'
--into #testCheckResults
--from inventory..Listing l
--where l.dealerid = @dealerID
--and l.ListingStatusID = 1
--and l.ListingTypeID = 1

--more than @range of new missing cost
insert into #testCheckResults
values ('new inventory missing cost', 
case when @newTotalCount = 0 then 'no new inventory' else
case when (@newNoCost/@newTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of new missing MSRP
insert into #testCheckResults
values ('new inventory missing MSRP', 
case when @newTotalCount = 0 then 'no new inventory' else 
case when (@newNoMSRP/@newTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of new missing invoice
insert into #testCheckResults
values ('new inventory missing invoice',
case when @newTotalCount = 0 then 'no new inventory' else 
case when (@newNoInvoice/@newTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of new missing final price
insert into #testCheckResults
values ('new inventory missing price',
case when @newTotalCount = 0 then 'no new inventory' else 
case when (@newNoPrice/@newTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of new final price more than @range off of website crawling
insert into #testCheckResults
values ('new inventory final price matching website',
(select case when @newTotalCount = 0 then 'no new inventory' else
case when (@newNoPrice / count(l.VIN))*100 > @range then 'fail' else 'pass' end end as 'pass/fail'
from inventory..listing l
left join inventory..ListingDetail ld on l.ListingID = ld.ListingID
where l.DealerID = @dealerid
and l.ListingStatusID = 1
and l.ListingTypeID = 1
and isnull(ld.price, 0.00) != 0.00))

--average number of photos on new inventory with at least one photo
insert into #testCheckResults
values ('new inventory average photo count',
case when @newTotalCount = 0 then 0 when @newwithphotos = 0 then 0 else round(@newPhotos / @newWithPhotos, 0) end)

--more than @range of new inventory missing photos
insert into #testCheckResults
values ('new inventory missing photos',
case when @newTotalCount = 0 then 'no new inventory' else
case when (@newNoPhotos/@newTotalCount) * 100 > @range then 'fail' else 'pass' end end)


/**
* USED INVENTORY
*/

--off hold count more than @range off of website crawling for used
insert into #testCheckResults
values ('used inventory count vs website',
(select case when @usedTotalCount != 0 then 
case when count(VIN) != 0 then
case when (@usedActiveCount/count(l.vin))*100 between @range and (100 + @range) then 'pass' else 'fail' end
else 'no used crawling' end end
from inventory..listing l
where l.dealerid = @dealerid
and l.ListingStatusID = 1
and l.listingtypeid = 2))

--more than @range of used missing cost
insert into #testCheckResults
values ('used inventory missing cost', 
case when @usedTotalCount = 0 then 'no used inventory' else 
case when (@usedNoCost/@usedTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of used missing final price
insert into #testCheckResults
values ('used inventory missing price', 
case when @usedTotalCount = 0 then 'no used inventory' else 
case when (@usedNoPrice/@usedTotalCount)*100 > @range then 'fail' else 'pass' end end)

--more than @range of used final price more than @range off of website crawling
insert into #testCheckResults
values ('used inventory final price matching website',
(select case when @usedTotalCount = 0 then 'no used inventory' else
case when count(l.VIN) = 0 then 'no used crawling' else
case when (@usedNoPrice / count(l.VIN))*100 > @range then 'fail' else 'pass' end end end
from inventory..listing l
left join inventory..ListingDetail ld on l.ListingID = ld.ListingID
where l.DealerID = @dealerid
and l.ListingStatusID = 1
and l.ListingTypeID = 2
and isnull(ld.price, 0.00) != 0.00))

--average number of photos on used inventory with at least one photo
insert into #testCheckResults
values ('used inventory average photo count',
case when @usedTotalCount = 0 then 0 when @usedWithPhotos = 0 then 0 else round(@usedPhotos / @usedWithPhotos, 0) end)

--more than @range of used inventory missing photos
insert into #testCheckResults
values ('used inventory missing photos',
case when @usedTotalCount = 0 then 'no used inventory' else
case when (@usedNoPhotos / @usedTotalCount) * 100 > @range then 'fail' else 'pass' end end)


--output the results to a JSON
select (select *
from #testCheckResults
for json path, root('unit tests')) as 'json'

--cleanup
drop table #testCheckResults