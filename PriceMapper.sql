/*
setting up to get the data we need
*/

--enter dealerid and either stock number or VIN of vehicle to check here
declare @dealerid int = 28965
declare @input varchar(75) = '5895'

declare @stockno varchar(75) = ''
declare @vin char(17) = ''
declare @sql varchar(max)

--allows for entering either the dealerID and stock number or dealerID and VIN - uses @input for one of them and figures out which one it is
set @stockno = case when len(@input) = 17 then (select stockno from ds..inventory where vin = @input and dealerid = @dealerid and inventorystatusid = 1) else '' end
set @vin = case when (len(@input) != 17 or @vin = '') then (select vin from ds..inventory where stockno = @input and dealerid = @dealerid and inventorystatusid = 1) else '' end
--collects either stockno or vin - whichever wasn't put into @input
set @vin = case when @vin = '' then (select vin from ds..inventory where stockno = @stockno and dealerid = @dealerid and inventorystatusid = 1) else @vin end
set @stockno = case when @stockno = '' then (select stockno from ds..inventory where vin = @vin and dealerid = @dealerid and inventorystatusid = 1) else @stockno end

--this grabs the most recent fileversionid for the DMS, IMS, and website automatically
declare @dmsfile bigint = (select top 1 ih.fileversionid
from integration..Source_Import_Dealer sid
left join Integration..import_history ih on ih.DealerID = sid.DealerID and ih.ImportProcessorID = sid.ImportProcessorID
where sid.DealerID = @dealerid
and sid.importtypeid = 1
order by ih.HistoryDate desc)

declare @imsfile bigint = (select top 1 ih.fileversionid
from integration..Source_Import_Dealer sid
left join Integration..import_history ih on ih.DealerID = sid.DealerID and ih.ImportProcessorID = sid.ImportProcessorID
where sid.DealerID = @dealerid
and sid.importtypeid = 4
order by ih.HistoryDate desc)

declare @wsfile bigint = (select top 1 ih.fileversionid
from integration..Source_Import_Dealer sid
left join Integration..import_history ih on ih.DealerID = sid.DealerID and ih.ImportProcessorID = sid.ImportProcessorID
where sid.DealerID = @dealerid
and sid.importtypeid = 2
order by ih.HistoryDate desc)

--builds a temp table for the column mappings for each import type
drop table if exists #tempcols
select idc.col as col, sid.ImportTypeID, dc.DataColID
into #tempcols
from Integration..import_dealercolmap idc
left join Integration..datacol dc on dc.DataColID = idc.DataColID
left join integration..Source_Import_Dealer sid on sid.DealerID = @dealerid and sid.ImportProcessorID = idc.ImportProcessorID
where idc.dealerid = @dealerid
and (dc.Description = 'stockNo' or dc.Description = 'VIN')
and sid.ImportTypeID in (1, 2, 4)
order by sid.ImportTypeID asc, dc.DataColID

--builds the column names for each field mapped to VIN or StockNo for either DMS, IMS, or website imports
--odd numbers will always be VIN, even numbers will always be stock number

--DMS
declare @col1 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 1 and datacolid = 1))
declare @col2 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 1 and datacolid = 19))
--IMS
declare @col3 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 4 and datacolid = 1))
declare @col4 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 4 and datacolid = 19))
--Website
declare @col5 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 2 and datacolid = 1))
declare @col6 varchar(6) = 'col' + convert(varchar, (select col from #tempcols where importtypeid = 2 and datacolid = 19))
--cleanup
drop table #tempcols

/*
begin body
*/

/*
query for raw data rows matching the supplied information
*/
set @sql = 'select case when fileversionid = ' + convert(varchar, @dmsfile) + ' then ''dms'' when FileVersionID = ' + convert(varchar, @imsfile) + ' then ''ims'' else ''website'' end as type, * 
from integration..File_Row_Column 
where FileVersionID in (' + convert(varchar, @dmsfile) + ', ' + convert(varchar, @imsfile) + ', ' + isnull(convert(varchar, @wsfile), '0') + ')
and ( (' + @col2 + ' like ''%'' + ''' + @stockno + ''' + ''%'' and ' + @col1 + ' = ''' + @vin + ''') or (' + @col4+ ' like ''%'' + ''' + @stockno + ''' + ''%'' and ' + @col3 + ' = ''' + @vin + ''') or (' + isnull(@col6, 'col0') + ' like ''%'' + ''' + @stockno + ''' + ''%'' and ' + isnull(@col5, 'col0') + ' = ''' + @vin + ''') )
order by case when fileversionid = ' + convert(varchar, @dmsfile) + ' then 1 when FileVersionID = ' + convert(varchar, @imsfile) + ' then 2 else 3 end'  

exec (@sql)

/*
original queries
*/

/*
selects raw data feed rows for supplied data
*/
--select *
--from integration..File_Row_Column
--where FileVersionID in ( @dmsfile, @imsfile, @wsfile)
--and (col69 like '%' + @stockno + '%' or col36 like '%' + @stockno + '%'  or col25 like '%' + @stockno + '%'
--or col64 = @vin or col84 = @vin  or col0 = @vin)
--order by case when fileversionid = @dmsfile then '1' when FileVersionID = @imsfile then '2' else '3' end  

/*
selects the pricing data that we loaded into VINCUE from the feed as well as all other fields
pulls from integration..inventory_import
*/
select case when fileversionid = @dmsfile then 'dms' when FileVersionID = @imsfile then 'ims' else 'website' end as type, pricemsrp, lotprice, price, cost, InvoicePrice, *
from integration..inventory_import
where fileversionid in ( @dmsfile, @imsfile, @wsfile)
and (stockno like '%' + @stockno + '%' or vin = @vin)
and dealerid = @dealerid
order by case when fileversionid = @dmsfile then '1' when FileVersionID = @imsfile then '2' else '3' end  

/*
selects the pricing data loaded into VINCUE
pulls from ds..inventory
*/
select cost, invoiceprice, pricemsrp, lotprice, price, ComparePrice, PriceSpecial, InventoryStatusId, DMSStatusId, ListingTypeID
from ds..inventory
where (stockno like '%' + @stockno + '%' or vin = @vin) and dealerid = @dealerid