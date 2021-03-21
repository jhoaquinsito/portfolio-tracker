-- warehouse.account_types definition

CREATE TABLE `account_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `last_update` varchar(255) DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;


-- warehouse.accounts definition

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `account_type_id` int(11) NOT NULL,
  `last_update` varchar(255) DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4;

-- warehouse.asset_quote definition

CREATE TABLE `asset_quote` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_id` int(11) NOT NULL,
  `quote_date` date NOT NULL,
  `last_update` varchar(255) DEFAULT current_timestamp(),
  `quote_chf` double DEFAULT NULL,
  `quote_usd` double DEFAULT NULL,
  `quote_btc` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=861 DEFAULT CHARSET=utf8mb4;

-- warehouse.asset_types definition

CREATE TABLE `asset_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `last_update` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4;

-- warehouse.assets definition

CREATE TABLE `assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `asset_type_id` int(11) NOT NULL,
  `last_update` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4;

-- warehouse.bookings definition

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_date` date NOT NULL,
  `booking_type` char(1) NOT NULL COMMENT 'C - credit ; D - debit',
  `transaction_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `amount` double NOT NULL,
  `asset_id` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `last_update` varchar(255) DEFAULT current_timestamp(),
  `reco_asset` int(11) DEFAULT NULL,
  `reco_rate` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=513 DEFAULT CHARSET=utf8mb4;

-- warehouse.daily_positions definition

CREATE TABLE `daily_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_id` int(11) NOT NULL,
  `position_date` date NOT NULL,
  `quantity` double NOT NULL,
  `last_update` varchar(255) DEFAULT NULL,
  `valuation_chf` double DEFAULT NULL,
  `valuation_usd` double DEFAULT NULL,
  `valuation_btc` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23361 DEFAULT CHARSET=utf8mb4;

-- warehouse.transactions definition

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) NOT NULL,
  `last_update` varchar(255) DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=156 DEFAULT CHARSET=utf8mb4;

-- triggers

CREATE DEFINER=`admin`@`localhost` TRIGGER transactions_update_last_update
AFTER UPDATE
ON transactions FOR EACH ROW
UPDATE transactions SET last_update = CURRENT_TIMESTAMP() WHERE id=NEW.id;


CREATE DEFINER=`admin`@`localhost` TRIGGER bookings_update_last_update
AFTER UPDATE
ON bookings FOR EACH ROW
UPDATE bookings SET last_update = CURRENT_TIMESTAMP() WHERE id=NEW.id;


CREATE DEFINER=`admin`@`localhost` TRIGGER assets_update_last_update
AFTER UPDATE
ON assets FOR EACH ROW
UPDATE assets SET last_update = CURRENT_TIMESTAMP() WHERE id=NEW.id;

-- warehouse.latest_quotes source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `warehouse`.`latest_quotes` AS
select
    `temp`.`id` AS `id`,
    `temp`.`asset_id` AS `asset_id`,
    `temp`.`quote_date` AS `quote_date`,
    `temp`.`last_update` AS `last_update`,
    `temp`.`quote_chf` AS `quote_chf`,
    `temp`.`quote_usd` AS `quote_usd`,
    `temp`.`quote_btc` AS `quote_btc`,
    `temp`.`max_date` AS `max_date`
from
    (
    select
        `aq`.`id` AS `id`,
        `aq`.`asset_id` AS `asset_id`,
        `aq`.`quote_date` AS `quote_date`,
        `aq`.`last_update` AS `last_update`,
        `aq`.`quote_chf` AS `quote_chf`,
        `aq`.`quote_usd` AS `quote_usd`,
        `aq`.`quote_btc` AS `quote_btc`,
        max(`aq`.`quote_date`) over ( partition by `aq`.`asset_id`) AS `max_date`
    from
        `warehouse`.`asset_quote` `aq`) `temp`
where
    `temp`.`quote_date` = `temp`.`max_date`;


-- warehouse.positions source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `warehouse`.`positions` AS
select
    `b`.`account_id` AS `account_id`,
    `b`.`asset_id` AS `asset_id`,
    sum(`b`.`amount`) AS `total_quantity`
from
    `warehouse`.`bookings` `b`
group by
    `b`.`account_id`,
    `b`.`asset_id`
having
    sum(`b`.`amount`) > 0;


-- warehouse.valuations source

CREATE OR REPLACE
ALGORITHM = UNDEFINED VIEW `warehouse`.`valuations` AS
select
    `p`.`account_id` AS `account_id`,
    `p`.`asset_id` AS `asset_id`,
    `p`.`total_quantity` AS `total_quantity`,
    round(`p`.`total_quantity` * `lq`.`quote_chf`, 2) AS `valuation_chf`,
    round(`p`.`total_quantity` * `lq`.`quote_usd`, 2) AS `valuation_usd`,
    round(`p`.`total_quantity` * `lq`.`quote_btc`, 8) AS `valuation_btc`
from
    (`warehouse`.`positions` `p`
join `warehouse`.`latest_quotes` `lq`)
where
    `p`.`asset_id` = `lq`.`asset_id`;

-- procedure to create positions by date

CREATE DEFINER=`admin`@`localhost` PROCEDURE `warehouse`.`daily_positions`()
BEGIN
            
	        DECLARE oldest_date DATE;
	       	DECLARE iterator_date DATE;
	        DECLARE daily_position_quantity DOUBLE;
	        DECLARE iterator_asset INT;
	       	-- TODO: replace this with array of assets or create select of asset_ids
	        DECLARE number_of_assets INT;
	       	SET number_of_assets = 20;
	       	
	       	-- find oldest
	        SELECT min(quote_date) INTO oldest_date FROM asset_quote;
			-- create / replace table
			CREATE OR REPLACE TABLE daily_positions (
			    id int NOT NULL AUTO_INCREMENT,
			    asset_id int NOT NULL,
			    position_date date NOT NULL,
			    quantity double NOT NULL,
			    last_update varchar(255),
			    valuation_chf double,
			    valuation_usd double,
			    valuation_btc double,
			    PRIMARY KEY (id)
			);
		
			-- initialize iterator
			SET iterator_date = oldest_date;

			-- for each day since earliest
			daily_loop: LOOP
			    IF iterator_date > CURDATE() THEN
			        LEAVE daily_loop;
			    ELSE
			    	-- initialize iterator
			    	SET iterator_asset = 1;
			    	-- for each asset at this iterator date
			    	asset_loop: LOOP
			    		IF iterator_asset > number_of_assets THEN
					        LEAVE asset_loop;
					    ELSE
					    	
					    	set daily_position_quantity = 0;
					    	-- calculate the position for this iterator date and asset
					    	select sum(b.amount) as 'quantity_at_iterator_date' into daily_position_quantity
							from bookings b
							where asset_id = iterator_asset
							and b.account_id in (select id from accounts a3 where account_type_id != 5 and id != 17)
							and b.booking_date <= iterator_date
							group by b.asset_id 
							having sum(b.amount) > 0;
						
							
							-- insert the quantity for this iterator asset and date
					    	INSERT INTO daily_positions (asset_id, position_date, quantity) VALUES (iterator_asset,iterator_date,daily_position_quantity);
					    	
					    	-- increase iterator asset
					    	SET iterator_asset = iterator_asset + 1;
					    
					    END IF;
				   	END LOOP;
				   	-- increase iterator date
				   	SET iterator_date = DATE_ADD(iterator_date, INTERVAL 1 DAY);
			    END IF;
			END LOOP;
        END;


-- procedure to create valuations by date

CREATE DEFINER=`admin`@`localhost` PROCEDURE `warehouse`.`daily_valuations`()
BEGIN
            
	        DECLARE oldest_date DATE;
	       	DECLARE iterator_date DATE;
	        DECLARE iterator_asset INT;
	        DECLARE iterator_date_quote_chf DOUBLE;
            DECLARE iterator_date_quote_usd DOUBLE;
            DECLARE iterator_date_quote_btc DOUBLE;
	       	-- TODO: replace this with array of assets or create select of asset_ids
	        DECLARE number_of_assets INT;
	       	SET number_of_assets = 20;
	       
	       	-- find oldest
	        SELECT min(quote_date) INTO oldest_date FROM asset_quote;
		
			-- initialize iterator
			SET iterator_date = oldest_date;

			-- for each day since earliest
			daily_loop: LOOP
			    IF iterator_date > CURDATE() THEN
			        LEAVE daily_loop;
			    ELSE
			    	
					    	
					    	set iterator_date_quote_chf = 0;
						    set iterator_date_quote_btc = 0;
						    set iterator_date_quote_usd = 0;
					    	
					    	-- get the quotes for that date 
					       	create temporary table tmp
					       	select *
							from (select *, max(quote_date) over (partition by asset_id) as max_date from asset_quote aq where quote_date <= iterator_date) as t1 where quote_date = max_date;
							
							-- do stuff with tmp...
				
					       	-- update the table with the valuations
					       	update daily_positions dp, tmp t set dp.valuation_chf = t.quote_chf * dp.quantity  where dp.position_date = iterator_date and dp.asset_id = t.asset_id;
							update daily_positions dp, tmp t set dp.valuation_usd = t.quote_usd * dp.quantity  where dp.position_date = iterator_date and dp.asset_id = t.asset_id;
							update daily_positions dp, tmp t set dp.valuation_btc = t.quote_btc * dp.quantity  where dp.position_date = iterator_date and dp.asset_id = t.asset_id;
  					       						    
					        -- output and cleanup
							drop temporary table if exists tmp;	
					    	
					    
					  
				   	-- increase iterator date
				   	SET iterator_date = DATE_ADD(iterator_date, INTERVAL 1 DAY);
			    END IF;
			END LOOP;
        END;




