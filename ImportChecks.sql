/**
* this is a set of unit tests to run after setting up the first round of imports for a dealership
* the tests check to see if the inventory has cost/invoice/MSRP, if the total count off hold matches the website, and if final price is close to the website
* if there is no new or used inventory, each test will say
* 
* enter dealer ID in @dealerid and run the full script
*/

--dealer ID to check here
declare @dealerid int = 56171
--percentage range here
declare @range int = 10


--variable block to set up counts
declare @minusRange int = 100 - @range
declare @newActiveCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = 50243
	and i.inventorystatusid = 1
	and i.donotexport = 0
	and i.listingtypeid = 1)
declare @usedActiveCount float = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.donotexport = 0
	and i.listingtypeid = 2)
declare @newTotalCount int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.listingtypeid = 1)
declare @usedTotalCount int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and i.listingtypeid = 2)
declare @newNoCost int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Cost, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @usedNoCost int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Cost, 0.00) = 0.00
	and i.listingtypeid = 2)
declare @newNoMSRP int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.pricemsrp, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @newNoInvoice int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.InvoicePrice, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @newNoPrice int = (select count(i.vin)
	from dealersite..inventory i
	where i.dealerid = @dealerid
	and i.inventorystatusid = 1
	and isnull(i.Price, 0.00) = 0.00
	and i.listingtypeid = 1)
declare @usedNoPrice int = (select count(i.vin)
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
declare @newWithPhotos int = @newTotalCount - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 1
	and ip.InventoryID is null)
declare @usedWithPhotos int = @usedTotalCount - (select count(i.InventoryID)
	from DealerSite..inventory i
	left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
	where i.dealerid = @dealerid
	and i.InventoryStatusId = 1
	and i.ListingTypeID = 2
	and ip.InventoryID is null)

/**
* NEW INVENTORY
*/

--off hold count more than @range off of website crawling for new
select 'new inventory count vs website' as 'NEW INVENTORY',
case when @newTotalCount = 0 then 'no new inventory' else case when (abs(@newActiveCount-count(l.vin))/count(l.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from DealerSite..inventory i 
left join inventory..Listing l on l.DealerID = i.DealerID and l.vin = i.vin
where i.dealerid = @dealerID
and i.InventoryStatusId = 1
and i.DoNotExport = 0
and l.ListingStatusID = 1
and i.ListingTypeID = 1

--more than @range of new missing cost
select 'new inventory missing cost', 
case when count(i.vin) = 0 then 'no new inventory' else 
case when (abs(@newNoCost-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 1

--more than @range of new missing MSRP
select 'new inventory missing MSRP', 
case when count(i.vin) = 0 then 'no new inventory' else 
case when (abs(@newNoMSRP-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 1

--more than @range of new missing invoice
select 'new inventory missing invoice',
case when count(i.vin) = 0 then 'no new inventory' else 
case when (abs(@newNoInvoice-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 1

--more than @range of new missing final price
select 'new inventory missing price',
case when count(i.vin) = 0 then 'no new inventory' else 
case when (abs(@newNoPrice-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 1

--more than @range of new final price more than @range off of website crawling
select 'new inventory final price matching website',
case when @newActiveCount = 0 then 'no new inventory' else
case when ((abs(count(i.vin) - @newActiveCount)) / @newActiveCount) * 100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from DealerSite..inventory i
left join inventory..Listing l on l.dealerid = i.dealerid and l.vin = i.vin
left join inventory..ListingDetail ld on ld.listingid = i.ListingID
where i.dealerid = @dealerid
and i.InventoryStatusId = 1
and i.DoNotExport = 0
and l.ListingStatusID = 1
and i.listingtypeid = 1
and ((isnull(i.price, 0.00) - isnull(ld.price, 0.00)) / isnull(ld.price, 0.00))*100 > 20
and ld.price is not null

select 'new inventory average photo count',
case when @newActiveCount = 0 then 0 else round(@newPhotos / @newWithPhotos, 0) end as 'count'

select 'new inventory missing photos',
case when @newActiveCount = 0 then 'no new inventory' else
case when ((abs(count(i.vin) - @newActiveCount)) / @newActiveCount) * 100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from DealerSite..inventory i
left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
where i.dealerid = @dealerid
and i.ListingTypeID = 1
and i.InventoryStatusId = 1
and ip.InventoryID is null

/**
* USED INVENTORY
*/

--off hold count more than @range off of website crawling for used
select 'used inventory count vs website' AS 'USED INVENTORY',
case when @usedactivecount != 0 then case when (abs(@usedActiveCount-count(l.vin))/count(l.vin))*100 between @range and @minusRange then 'fail' else 'pass' end else 'no used inventory' end as 'pass/fail'
from DealerSite..inventory i 
left join inventory..Listing l on l.DealerID = i.DealerID and l.vin = i.vin
where i.dealerid = @dealerID
and i.InventoryStatusId = 1
and i.DoNotExport = 0
and l.ListingStatusID = 1
and i.listingtypeid = 2

--more than @range of used missing cost
select 'used inventory missing cost', 
case when @usedActiveCount = 0 then 'no used inventory' else 
case when (abs(@usedNoCost-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 1

--more than @range of used missing final price
select 'used inventory missing price', 
case when @usedActiveCount = 0 then 'no used inventory' else 
case when (abs(@usedNoPrice-count(i.vin))/count(i.vin))*100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from dealersite..inventory i
where i.dealerid = @dealerid
and i.inventorystatusid = 1
and i.listingtypeid = 2

--more than @range of used final price more than @range off of website crawling
select 'used inventory final price matching website',
case when @usedActiveCount = 0 then 'no used inventory' else
case when ((abs(count(i.vin) - @usedActiveCount)) / @usedActiveCount) * 100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from DealerSite..inventory i
left join inventory..Listing l on l.dealerid = i.dealerid and l.vin = i.vin
left join inventory..ListingDetail ld on ld.listingid = i.ListingID
where i.dealerid = @dealerid
and i.InventoryStatusId = 1
and i.DoNotExport = 0
and l.ListingStatusID = 1
and i.listingtypeid = 2
and ((isnull(i.price, 0.00) - isnull(ld.price, 0.00)) / isnull(ld.price, 0.00))*100 > 20
and ld.price is not null

select 'used inventory average photo count',
case when @usedActiveCount = 0 then 0 else round(@usedPhotos / @usedWithPhotos, 0) end as 'count'

select 'used inventory missing photos',
case when @usedActiveCount = 0 then 'no used inventory' else
case when ((abs(count(i.vin) - @usedActiveCount)) / @usedActiveCount) * 100 between @range and @minusRange then 'fail' else 'pass' end end as 'pass/fail'
from DealerSite..inventory i
left join DealerSite..inventoryphoto ip on i.InventoryID = ip.InventoryID and i.dealerid = ip.DealerID
where i.dealerid = @dealerid
and i.ListingTypeID = 2
and i.InventoryStatusId = 1
and ip.InventoryID is null