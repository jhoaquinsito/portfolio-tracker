-- readable: valuations per account and assets
select a.name, a2.name, v.total_quantity, v.valuation_chf, v.valuation_usd, v.valuation_btc
from valuations v, accounts a, assets a2 
where v.account_id = a.id and v.asset_id = a2.id and a.account_type_id != 5;

-- readable: valuations per assets
select a2.name, at2.name , sum(v.total_quantity), sum(v.valuation_chf), sum(v.valuation_usd), sum(v.valuation_btc)
from valuations v, assets a2 , asset_types at2 
where v.asset_id = a2.id and a2.asset_type_id = at2.id 
group by v.asset_id;

-- readable: valuations per asset type
select at2.name , sum(v.total_quantity), sum(v.valuation_chf), sum(v.valuation_usd), sum(v.valuation_btc)
from valuations v, assets a2 , asset_types at2 
where v.asset_id = a2.id and a2.asset_type_id = at2.id 
group by at2.id;

-- readable: valuations per account
select a.name,  sum(v.total_quantity), sum(v.valuation_chf), sum(v.valuation_usd), sum(v.valuation_btc) 
from valuations v, accounts a
where v.account_id = a.id 
group by v.account_id ;

-- readable: total size
select sum(v.valuation_chf), sum(v.valuation_usd), sum(v.valuation_btc) 
from valuations v 



-- run reco global
select booking_type, sum(reco_rate * amount) from bookings b group by booking_type ;

-- reco per transaction, only unsuccessful ones
select transaction_id, round(sum(reco_rate * amount),6) from bookings b group by transaction_id having sum(reco_rate * amount) != 0;

-- to fix the problematic ones
select *, reco_rate*amount from bookings b where transaction_id = 155

-- readable store procedure outcomes
select dp.position_date, a2.name, at2.name, dp.quantity, dp.valuation_btc , dp.valuation_chf , dp.valuation_usd from daily_positions dp, assets a2, asset_types at2 where valuation_btc is not null and a2.asset_type_id = at2.id and dp.asset_id = a2.id 


-- SP calls after data updates
CALL daily_positions();
CALL daily_valuations();
