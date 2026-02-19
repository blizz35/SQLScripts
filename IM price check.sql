declare @dealerID int =  --dealer id here

select i.stockno,
	i.vin, 
	price,
	case when i.listingtypeid = 1 then price - isnull(lotprice, pricemsrp) else null end as rebates, 
	lotprice, 
	isnull(lotprice, pricemsrp) - pricemsrp as discount, 
	pricemsrp, 
	isnull(AccessoryFee, 0) as AccessoryFee, 
	cost, 
	InvoicePrice, 
	Holdback, 
	DMSStatusId, 
	DoNotExport, 
	CertifiedInd, 
	isnull(DealerCertifiedInd, 0) as DealerCertifiedInd, 
	WholesaleInd, 
	dit.tag, 
	i.ListingTypeID,
	isnull(l.listingstatusid, 0) as ListingStatusID,
	l.Url, 
	i.*
from dealersite..inventory i with(nolock)
	left join DealerSite..InventoryTag it with(nolock) on it.InventoryId = i.inventoryID
	left join vincue..dealerinventorytag dit with(nolock) on it.TagId = dit.TagID
	left join inventory..listing l with(nolock) on i.DealerID = l.dealerid and i.listingid = l.ListingID
where i.dealerid = @dealerID
	and i.dmsstatusid = 1
	--and i.ListingTypeID = 1
	and i.DoNotExport = 0
	--and i.stockno in ('')
	--and i.vin in('')
	--and i.CertifiedInd = 1
	--and i.DealerCertifiedInd = 1
	--and i.WholesaleInd = 1
	--and it.TagId is not null
order by isnull(i.WholesaleInd, 0), 
	i.ListingTypeid, 
	i.StockNo,
	i.Make

select i.listingtypeid,
	i.stockno, 
	i.vin, 
	count(p.photourl) as photocount
from dealersite..inventory i
	left join DealerSite..InventoryPhoto p on i.inventoryid = p.inventoryid
where i.dealerid = @dealerID
	and i.dmsstatusid = 1
	--and i.ListingTypeID = 2
	and i.DoNotExport = 0
	--and i.stockno in ('')
	--and i.vin in('')
	--and i.CertifiedInd = 1
	--and i.DealerCertifiedInd = 1
	--and i.WholesaleInd = 1
group by i.stockno, 
	i.vin,
	i.ListingTypeID
order by i.listingtypeid,
	count(p.photourl),
	i.StockNo