/**
* 
*/
use integration

declare @dealerid int = 116542 

declare @accountName varchar(100) = (select name
	from admin..account a 
	left join admin..Account_Dealer ad on a.AccountID = ad.AccountID
	where ad.dealerid = @dealerid)
declare @accountID varchar(25) = (select accountID
	from admin..Account_Dealer
	where dealerid = @dealerid)
declare @autoOffHold varchar(25) = (select case 
		when AutoOffHold = 1 then 'Enabled' 
		when AutoOffHold = 0 and NewAutoOffHold = 1 then 'New Only' 
		when AutoOffHold = 0 and UsedAutoOffHold = 1 then 'Used Only' 
		else 'Disabled' end 
	from source_import_dealer
	where dealerid = @dealerid 
	and importtypeid = 1)
declare @currDMS varchar(100) = (select si.importname
	from source_import_dealer sid
	left join source_import si on si.importprocessorid = sid.importprocessorid
	where sid.dealerid = @dealerid
	and sid.importtypeid = 1)
declare @dmsFile varchar(max) = (select filename
	from source_import_dealer
	where dealerid = @dealerid
	and importtypeid = 1)
declare @dmsAdd varchar(100) = (select top 1 cast(historydate as date)
	from source_import_dealer_history
	where dealerid = @dealerid
	and importtypeid = 1
	order by historydate)
declare @dmsLastRun varchar(100) = (select top 1 historydate
	from import_history ih
	left join source_import_dealer sid on sid.dealerid = ih.dealerid and sid.importprocessorid = ih.importprocessorid
	where ih.dealerid = 116542
	and sid.importtypeid = 1
	order by historydate desc)
declare @currWeb varchar(100) = (select si.importname
	from source_import_dealer sid
	left join source_import si on si.importprocessorid = sid.importprocessorid
	where sid.dealerid = @dealerid
	and sid.importtypeid = 2)
declare @webFile varchar(max) = (select filename
	from source_import_dealer
	where dealerid = @dealerid
	and importtypeid = 2)
declare @currIM varchar(100) = (select si.importname
	from source_import_dealer sid
	left join source_import si on si.importprocessorid = sid.importprocessorid
	where sid.dealerid = @dealerid
	and sid.importtypeid = 4)
declare @imFile varchar(max) = (select filename
	from source_import_dealer
	where dealerid = @dealerid
	and importtypeid = 4)
declare @currPhoto varchar(100) = (select string_agg(si.importname, ', ') within group (order by sid.importprocessorid)
	from source_import_dealer sid
	left join source_import si on si.importprocessorid = sid.importprocessorid
	where sid.dealerid = @dealerid
	and sid.importtypeid = 3)
declare @photoFile varchar(max) = (select string_agg(filename, ', ') within group (order by importprocessorid)
	from source_import_dealer
	where dealerid = @dealerid
	and importtypeid = 3)
declare @currCRM varchar(100) = (select case when exists(select value from admin..dealer_setting_varchar where dealerid = @dealerid and name = 'eleads_subscriptionId') then 'E-Leads' else si.importname end
	from source_import_crmdealer sid
	left join crmsource_import si on si.importprocessorid = sid.importprocessorid
	where sid.dealerid = @dealerid)
declare @crmFile varchar(max) = (select case when @currCRM = 'E-Leads' then value else '' end
	from admin..dealer_setting_varchar 
	where dealerid = @dealerid
	and name = 'eleads_subscriptionId')
if @crmFile is null
	set @crmFile = (select filename
		from source_import_crmdealer
		where dealerid = @dealerid)
declare @RRID varchar(max) = (select value
	from admin..dealer_setting_varchar
	where dealerid = @dealerid
	and name = 'rr_tenantID')
declare @RRDate varchar(max) = (select updateTS
	from admin..dealer_setting_varchar
	where dealerid = @dealerid
	and name = 'rr_tenantID')
declare @GAID varchar(max) = (select value
	from admin..dealer_setting_varchar
	where dealerid = @dealerid
	and name = 'ga4_property_id')
declare @GADate varchar(max) = (select updateTS
	from admin..dealer_setting_varchar
	where dealerid = @dealerid
	and name = 'ga4_property_id')

drop table if exists #setupDetails
create table #setupDetails (name varchar(100), value varchar(max))
drop table if exists #exportDetails
--create table #dealerSyndicationDetails (name varchar(100), value varchar(max), timestamp datetime)

insert into #setupDetails (name)
values ('Dealer Account Setup')

insert into #setupDetails
values ('Dealer ID', cast(@dealerid as varchar)),
('Dealer Name', (select dealername from admin..dealer where dealerid = @dealerid and clientind = 1)),
('Group Name', @accountName),
('Group ID', @accountID),
('Website Provider', (select websitecompany from admin..dealer where dealerid = @dealerid and clientind = 1)),
('Website URL', (select mainURL from admin..dealer where dealerid = @dealerid and clientind = 1))


insert into #setupDetails (name)
values ('Import Settings')

insert into #setupDetails
values ('Auto Off Hold', @autoOffHold),
('Current DMS Import', @currDMS),
('DMS File Name', @dmsFile),
('Current DMS Setup Date', @dmsAdd),
('DMS Feed Last Ran', @dmsLastRun),
('Current Website Import', isnull(@currWeb, 'No Website Feed')),
('Website File Name', isnull(@webFile, 'No Website Feed')),
('Current IMS Import', isnull(@currIM, 'No IMS Feed')),
('IMS File Name', isnull(@imFile, 'No IMS File')),
('Current Photo Import(s)', isnull(@currPhoto, 'No Photo Feed')),
('Photo File Name(s)', isnull(@photoFile, 'No Photo File')),
('Current CRM Import', isnull(@currCRM, 'No CRM Feed')),
('CRM File Name', isnull(@crmFile, 'No CRM File'))


insert into #setupDetails (name)
values ('Integration Settings')

insert into #setupDetails
values ('Rapid Recon Tenant ID', @RRID),
('Rapid Recon Activation Date', @RRDate),
('GA4 Property ID', @GAID),
('GA4 Activation Date', @GADate)


select replace(replace(name, 'export_', ''), '_uid', '') as exportName, case when value = '' then cast(@dealerid as varchar) else value end as exportID, updateTS as createDate
into #exportDetails
from dealersite..export_setting_varchar
where dealerid = @dealerid
and name like '%uid'

select *
from #setupDetails
select *
from #exportDetails

drop table #setupDetails
drop table #exportDetails