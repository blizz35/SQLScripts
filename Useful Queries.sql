--this pulls the file name that we processed as well as when that file was dropped onto our import server and when the importer processed it
--put the name of the import in the quotes and the dealer ID on the line below
select left(right(fi.filename, len(fi.filename) - 1), charindex('\', fi.FileName, 2) - 2) as ImportName, fi.fileid, fi.FileName, fi.DirectoryPath, fi.Add_Date, ih.FileVersionID, ih.HistoryDate
from integration..Import_History ih
left join Integration..file_version fv on ih.FileVersionID = fv.FileVersionID
left join Integration..File_Info fi on fv.fileid = fi.FileID
where ih.dealerid = 147766  --dealerid here
and ih.ImportProcessorID = (select ImportProcessorID from Integration..Source_Import where ImportName = 'cdk') --import name here
and ih.HistoryDate > dateadd(day, -5, getdate())
order by ih.HistoryDate desc

--this is an inventory history dump that includes the updating user's name
--add whatever field you need to the select clause
--currently built to search by VIN but can also do stock + dealerID
select 
	--d.dealername,
	ih.HistoryDate,
	case 
		when ih.Update_UserId = -1 then 'Import'
		when ih.update_userid = -2 then 'Pricing Rule'
		when ih.update_userid = -4 then 'Front/back Gross'
		when ih.update_userid = -5 then 'DMS Writeback'
		else l.First_Name + ' ' + l.Last_Name end as Name,
	case
		when ih.HistoryUserID = -1 then 'Import'
		when ih.HistoryUserID = -2 then 'Pricing Rule'
		when ih.HistoryUserID = -4 then 'Front/back Gross'
		when ih.HistoryUserID = -5 then 'DMS Writeback'
		else l2.First_Name + ' ' + l2.Last_Name end as Name2,
	ih.cost,
	ih.*
from 
	dealersite..inventory i
left join
	ds..inventory_hist ih on i.InventoryID = ih.inventoryid
left join 
	admin..Login l 
		on l.Login_ID = ih.Update_UserId
left join
	admin..login l2
		on l2.login_id = ih.HistoryUserID
left join
	admin..dealer d
		on d.dealerid = i.dealerid
where i.vin = 'JM1NC2PF0F0242671' --VIN here
--where i.stockno = 'P9816' and i.dealerid = 55781 --stocknumber and dealerid here
--where i.inventoryid = 382394331
order by ih.historydate desc

--pulls up current information on a vehicle
select *
from DealerSite..inventory
where inventoryid = 391461861

select *
from DealerSite..Inventory
where stockno in ('526492')
and dealerid = 124112
and InventoryStatusId = 1

select donotexport, pricemsrp, lotprice, price, *
from DealerSite..Inventory
where vin in ('1C6SRFFT0TN302079')
and InventoryStatusId = 1

--pulls up counts of active new and used grouped by make and hold status
select
	case when listingtypeid = 1 then 'New' else 'Used' end,
	make,
	case when donotexport = 0 then 'Off Hold' else 'On Hold' end,
	count(vin)
from DealerSite..inventory
where dealerid = 220502 --dealerID here
and InventoryStatusId = 1
group by listingtypeid, Make, donotexport
order by listingtypeid, make, donotexport

--pulls up counts of active new and used inventory as well as what is on and off hold for each
	select 
		case when listingtypeid = 1 then 'New' else 'Used' end,
		case when donotexport = 0 then 'Off Hold' else 'On Hold' end,
		count(vin)
	from dealersite..inventory
	where dealerid = 125324 --dealerID here
	and inventorystatusid = 1
	group by listingtypeid, donotexport
	order by listingtypeid, donotexport

--pulls new/used and on/off hold counts for all dealers in a group
select 
	d.dealerid, 
	d.dealername,
	d.address,
	case when listingtypeid = 1 then 'New' else 'Used' end,
	case when donotexport = 0 then 'Off Hold' else 'On Hold' end,
	count(vin)
from dealersite..inventory i
left join admin..Dealer d on d.dealerid = i.DealerID
left join admin..Account_Dealer ad on d.DealerID = ad.DealerID
left join admin..account a on a.AccountID = ad.AccountID
where inventorystatusid = 1
and d.ClientInd = 1
and a.name like '%cma%'
and d.city like 'Charlottesville'
group by d.dealerid, d.dealername, d.address, listingtypeid, donotexport
order by d.dealerid, d.dealername, d.address, listingtypeid, donotexport

--gets total count of active vehicles for a dealer
select count(vin)
from DealerSite..inventory
where DealerID = 185560
and inventorystatusid = 1

--onboarding price mapping check
select stockno, cost, invoiceprice, pricemsrp, lotprice, price, VIN, ListingTypeID, ComparePrice
from DealerSite..Inventory
where dealerid = 43934 
and stockno in ('NN6183', 'NN6190', 'PP2202', 'PP2262')
and InventoryStatusId = 1
order by ListingTypeID, stockno

--pulls up all photos for a piece of inventory
--requires inventoryid
select *
from DealerSite..InventoryPhoto
where inventoryid = 391238011
order by SortOrder

--pulls up all photos for a piece of inventory
--uses VIN to find vehicle
select ip.*
from DealerSite..inventory i
left join DealerSite..inventoryphoto ip on i.inventoryid = ip.InventoryID
where i.vin = '3TMLB5JN4TM262507' 
and i.InventoryStatusId = 1
order by ip.SortOrder

--pulls up all photos for a piece of inventory
--uses stock number and dealer ID to find vehicle
select ip.*
from DealerSite..inventory i
left join DealerSite..inventoryphoto ip on i.inventoryid = ip.InventoryID
where i.StockNo in ('M260086') and i.dealerid = 50366
order by inventoryid, SortOrder

--pulls up vins and the count of photos on each vin for a dealer
select i.vin, count(p.photourl) as photoCount
from DealerSite..inventory i
left join DealerSite..InventoryPhoto p on i.InventoryID = p.InventoryID
where i.dealerid = 13619 --dealerID here
and i.InventoryStatusId = 1
--and i.DoNotExport = 0
group by i.VIN
order by 2

--pulls up information on a user based on either username or login_ID
select *
from admin..login
where uid like '%dclark@lexusofcoloradosprings.com%'

select *
from admin..login
where Login_ID = 416695

--this is a query Dale runs to get import errors for the current day
select substring(sql,charindex('dealerid =',sql),25),dealerid,ImportName,ie.*
from integration..import_error ie
left join integration..import_history ih on ie.FileVersionID = ih.FileVersionID
left join Integration..Source_Import si on si.ImportProcessorID = ih.ImportProcessorID
where ie.add_date >= convert(char(10),getdate(),101)
and step != 'PhotoProcessor:SortOrder'
order by ie.add_date desc

--gets information on the raw file based on FileVersionID
select f.*
from integration..File_Info f
left join Integration..File_Version fv on fv.fileid = f.fileid
where FileVersionID = 12915313

select *
from integration..File_Info f
left join Integration..File_Version fv on fv.fileid = f.fileid
where filename like '%116563srp%'

select *
from integration..file_info f
left join Integration..File_Version fv on fv.fileid = f.fileid
where filename like '%dealertrackapi%'
order by fv.Add_Date desc

--these three grab information on dealers in general based on their address, name, or website URL
select *
from admin..dealer
where address like '%1777 West Fourth Street%'
and ClientInd = 1

select *
from admin..dealer
where DealerName like '%pilson%'

select *
from admin..dealer
where MainUrl like '%moses-cadillac%'

select *
from admin..dealer
where dealerid = 218684
and ClientInd = 1

--searches for a string inside sprocs
SELECT DISTINCT
       o.name AS Object_Name,
       o.type_desc
FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
WHERE m.definition Like '%gtxm1070.siteground.biz%'
and o.type_desc = 'SQL_STORED_PROCEDURE'

--check for CDKFISold imports that haven't been set up yet and have a file
select si.ImportName, sid.dealerid, sid.Add_Date, sid.filename, sid.addvehicles, sid.newdeactivate, sid.useddeactivate
from integration..source_import_dealer sid
left join Integration..source_import si on si.ImportProcessorID = sid.ImportProcessorID
where si.ImportName = 'CDKFISold'
and (sid.FileName is null or sid.AddVehicles = 1 or sid.NewDeactivate = 1 or sid.UsedDeactivate = 1)
and convert(date, sid.add_date) < convert(date, getdate())

--returns a list of CDK dealers without the sold data feed set up
select sid.dealerid
from Integration..source_import_dealer sid
left join Integration..Source_Import si on si.ImportProcessorID = sid.ImportProcessorID
where si.ImportName like 'CDK%'
and sid.Add_Date > dateadd(day, -30, getdate())
group by sid.dealerid
having count(sid.importdealerid) = 1

--checks for all dealers with a given make associated
--be careful - the popular OEMs will return a ton of rows
select d.DealerID, d.DealerName, d.Address, d.city, d.State, m.MakeName
from inventory..make m
left join admin..DealerMake dm on m.makeid = dm.makeid
left join admin..dealer d on d.dealerid = dm.dealerid
where m.MakeName = 'jaguar'
and d.ClientInd = 1
order by DealerName

--searches for dealers by the group name
--can also filter that list by OEM
select d.dealerid, d.dealername, d.Address, d.city, d.state, a.name, isnull(string_agg(convert(nvarchar(max), m.makename), ', ') within group (order by m.makename asc), 'No Make Selected') as franchises
from admin..account a
left join admin..Account_Dealer ad on a.AccountID = ad.AccountID
left join admin..Dealer d on d.dealerid = ad.DealerID
left join admin..DealerMake dm on d.dealerid = dm.DealerID
left join inventory..make m on m.MakeID = dm.MakeID
where a.Name like '%briggs%'
and d.ClientInd = 1
--and d.city = 'Rochester'
--and m.MakeName = 'volkswagen'
group by d.dealerid, d.dealername, d.Address, d.city, d.state, a.name
order by d.city