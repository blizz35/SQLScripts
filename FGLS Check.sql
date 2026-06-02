/**
* Final Go Live Settings Check v1.2
* 
* enter dealer ID below and run
* 
* returns a set of result tables with:
* imports set up on that dealer ID and applicable settings for that import
*	filename, auto off hold for DMS feeds only, import types, photo settings for photo importing feeds only
* all fields that will import data for a vehicle
*	this is broken out by import and if it'll update every time the feed runs or only when a vehicle first imports
*	also lists any mappings broken out by mapping type and the SQL set on that field
* auto tagging setups listing import, tag name and SQL condition to apply the tag
* all filters on all imports for applied to this dealer ID along with the SQL that is being filtered out
*/

--dealer ID here
declare @dealerid int = 


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
left join integration..source_import_dealer_tagging sidt on sidt.importprocessorid = sid.ImportDealerID
where sid.DealerID = @dealerid
order by sid.ImportTypeID

--selects the fields that are mapped from the fields we would typically need to update during a go live
select si.ImportName, 
	d.Description, 
	id.col, 
	case when sidm.MappingTypeID = 1 then 'Transform' 
		when sidm.MappingTypeID = 2 then 'Filter' 
		when sidm.MappingTypeID = 3 then 'Validate' 
		when sidm.mappingtypeid = 4 then 'Conditional Update' 
		else '' end as 'Mapping Type', 
	case when sidm.SQL = 'd.listingtypeid = 1' then '~~ updating new only ~~' 
		when sidm.sql = 'd.listingtypeid = 2' then '~~ updating used only ~~' 
		when sidm.sql is null then '' 
		else sidm.SQL end as SQL,
	case when i.Updateable = 1 then 'Updating'
		when sid.ImportTypeID = 1 and i.Updateable = 0 then 'Initially importing'
		else null end as 'Updatable'
from integration..import_dealercolmap id
left join Integration..datacol d on id.DataColID = d.DataColID
left join Integration..source_import si on si.ImportProcessorID = id.ImportProcessorID
left join Integration..Source_Import_Dealer sid on sid.DealerID = id.DealerID and sid.ImportProcessorID = si.ImportProcessorID
left join Integration..ImportSourceDealerColumns i on i.ImportDealerID = sid.ImportDealerID and i.DataColID = d.DataColID
left join integration..source_import_dealer_mapping sidm on sid.dealerid = sidm.DealerID and sid.ImportProcessorID = sidm.ImportProcessorID and sidm.DataColID = id.DataColID
where id.DealerID = @dealerid
--and d.Description in ('wholesaleind', 'certifiedind', 'description', 'photourl', 'pricemsrp', 'price', 'lotprice', 'cost', 'invoiceprice', 'donotexport')
and (i.Updateable = 1 or sid.ImportTypeID = 1)
and i.Updateable is not null
order by sid.ImportTypeID, i.Updateable desc, d.Description

--selects all tags with autotagging and the condition to mark a vehicle with that tag
select si.importname, sidt.tagname, sidt.sql as 'Tagging SQL'
from integration..source_import_dealer sid
left join integration..source_import si on si.ImportProcessorID = sid.ImportProcessorID
left join integration..Source_Import_Dealer_Tagging sidt on sidt.ImportProcessorID = sid.ImportDealerID
where sid.dealerid = @dealerid
and sidt.tagname is not null

--selects the fields that are mapped with a filter on them as well as the contents of that filter
select si.ImportName, 
	d.Description, 
	id.col, 
	case when sidm.SQL = 'd.listingtypeid = 1' then '~~ updating new only ~~' 
		when sidm.sql = 'd.listingtypeid = 2' then '~~ updating used only ~~' 
		when sidm.sql is null then '' 
		else sidm.SQL end as 'Filter SQL'
from integration..import_dealercolmap id
left join Integration..datacol d on id.DataColID = d.DataColID
left join Integration..source_import si on si.ImportProcessorID = id.ImportProcessorID
left join Integration..Source_Import_Dealer sid on sid.DealerID = id.DealerID and sid.ImportProcessorID = si.ImportProcessorID
left join Integration..ImportSourceDealerColumns i on i.ImportDealerID = sid.ImportDealerID and i.DataColID = d.DataColID
left join integration..source_import_dealer_mapping sidm on sid.dealerid = sidm.DealerID and sid.ImportProcessorID = sidm.ImportProcessorID and sidm.DataColID = id.DataColID
where id.DealerID = @dealerid
and sidm.MappingTypeID = 2
order by sid.ImportTypeID, d.Description