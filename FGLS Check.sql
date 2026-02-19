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