-- insert quotes

insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (4, date('2021-03-13'),0,59900,1); -- btc
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (5, date('2021-03-13'),0,1887,0); -- eth
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (9, date('2021-03-13'),0,37.87,0); -- dot
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (10, date('2021-03-13'),0,2218.46,0); -- mkr
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (11, date('2021-03-13'),0,456.85,0); -- comp
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (12, date('2021-03-13'),0,48.82,0); -- wnxm
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (18, date('2021-03-13'),0,0.8174,0); -- bat
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (19, date('2021-03-13'),0,32.81,0); -- uni
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (20, date('2021-03-13'),0,30.28,0); -- link

insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (8, date('2021-03-13'),0,152.83,0); -- rs
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (13, date('2021-03-13'),0,62.9,0); -- intc
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (16, date('2021-03-13'),0,25.81,0); -- reet
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (14, date('2021-03-13'),102.8,0,0); -- sqn
insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (15, date('2021-03-13'),51.29,0,0); -- auusi

insert into asset_quote (asset_id, quote_date, quote_chf, quote_usd, quote_btc) values (1, date('2021-03-13'),0.93,1,0); -- usd/chf rates

-- usd to chf
update asset_quote set quote_chf = quote_usd * 0.93 where quote_chf = 0;

-- chf to usd
update asset_quote set quote_usd = quote_chf / 0.93 where quote_usd = 0;

-- usd to btc
update asset_quote set quote_btc = quote_usd/59900 where quote_btc = 0;