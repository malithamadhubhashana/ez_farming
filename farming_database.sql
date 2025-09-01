-- SQL file for manual database setup (optional)
-- The script will automatically create these tables, but you can run this manually if needed

-- Farming plants table
CREATE TABLE IF NOT EXISTS `farming_plants` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(255) NOT NULL,
    `crop_type` VARCHAR(50) NOT NULL,
    `coords_x` FLOAT NOT NULL,
    `coords_y` FLOAT NOT NULL,
    `coords_z` FLOAT NOT NULL,
    `zone_index` INT NOT NULL,
    `stage` INT DEFAULT 1,
    `max_stages` INT NOT NULL,
    `plant_time` BIGINT NOT NULL,
    `last_growth_time` BIGINT NULL,
    `last_water_time` BIGINT NULL,
    `needs_water` BOOLEAN DEFAULT FALSE,
    `fertilized` BOOLEAN DEFAULT FALSE,
    `diseased` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_coords` (`coords_x`, `coords_y`, `coords_z`),
    INDEX `idx_zone` (`zone_index`),
    INDEX `idx_stage` (`stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player farming statistics table
CREATE TABLE IF NOT EXISTS `farming_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(255) UNIQUE NOT NULL,
    `level` INT DEFAULT 1,
    `experience` INT DEFAULT 0,
    `total_plants` INT DEFAULT 0,
    `total_harvests` INT DEFAULT 0,
    `total_seeds_planted` INT DEFAULT 0,
    `total_crops_sold` INT DEFAULT 0,
    `total_money_earned` INT DEFAULT 0,
    `favorite_crop` VARCHAR(50) NULL,
    `achievements` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_level` (`level`),
    INDEX `idx_experience` (`experience`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Farming transactions log (optional - for advanced economics)
CREATE TABLE IF NOT EXISTS `farming_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(255) NOT NULL,
    `transaction_type` ENUM('buy', 'sell') NOT NULL,
    `item_type` VARCHAR(50) NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `quantity` INT NOT NULL,
    `unit_price` INT NOT NULL,
    `total_amount` INT NOT NULL,
    `quality` FLOAT DEFAULT 1.0,
    `shop_location` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player_identifier` (`player_identifier`),
    INDEX `idx_transaction_type` (`transaction_type`),
    INDEX `idx_item_type` (`item_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server settings table (for persistent config)
CREATE TABLE IF NOT EXISTS `farming_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) UNIQUE NOT NULL,
    `setting_value` TEXT NOT NULL,
    `setting_type` ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    `description` VARCHAR(255) NULL,
    `updated_by` VARCHAR(255) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default server settings
INSERT INTO `farming_settings` (`setting_key`, `setting_value`, `setting_type`, `description`) VALUES
('current_season', 'spring', 'string', 'Current farming season'),
('season_start_time', UNIX_TIMESTAMP(), 'number', 'When current season started'),
('global_growth_modifier', '1.0', 'number', 'Global growth speed modifier'),
('pest_chance_modifier', '1.0', 'number', 'Global pest chance modifier'),
('market_demand_modifier', '1.0', 'number', 'Global market demand modifier')
ON DUPLICATE KEY UPDATE `setting_value` = VALUES(`setting_value`);

-- Create indexes for better performance
CREATE INDEX `idx_farming_plants_compound` ON `farming_plants` (`player_identifier`, `stage`, `zone_index`);
CREATE INDEX `idx_farming_stats_compound` ON `farming_stats` (`level`, `experience`);

-- Create views for easier querying
CREATE OR REPLACE VIEW `active_plants` AS
SELECT 
    p.*,
    s.level as player_level,
    s.experience as player_experience
FROM `farming_plants` p
LEFT JOIN `farming_stats` s ON p.player_identifier = s.player_identifier
WHERE p.stage < p.max_stages;

CREATE OR REPLACE VIEW `ready_plants` AS
SELECT 
    p.*,
    s.level as player_level,
    s.experience as player_experience
FROM `farming_plants` p
LEFT JOIN `farming_stats` s ON p.player_identifier = s.player_identifier
WHERE p.stage >= p.max_stages;

-- Optional: Create triggers for automatic stat updates
DELIMITER //

CREATE TRIGGER `update_plant_stats_after_insert` 
AFTER INSERT ON `farming_plants`
FOR EACH ROW
BEGIN
    INSERT INTO `farming_stats` (player_identifier, total_plants, total_seeds_planted)
    VALUES (NEW.player_identifier, 1, 1)
    ON DUPLICATE KEY UPDATE 
        total_plants = total_plants + 1,
        total_seeds_planted = total_seeds_planted + 1;
END//

CREATE TRIGGER `update_harvest_stats_after_delete` 
BEFORE DELETE ON `farming_plants`
FOR EACH ROW
BEGIN
    IF OLD.stage >= OLD.max_stages THEN
        UPDATE `farming_stats` 
        SET total_harvests = total_harvests + 1
        WHERE player_identifier = OLD.player_identifier;
    END IF;
END//

DELIMITER ;

-- Create stored procedures for common operations
DELIMITER //

-- Procedure to get player farming summary
CREATE PROCEDURE `GetPlayerFarmingSummary`(IN p_identifier VARCHAR(255))
BEGIN
    SELECT 
        s.level,
        s.experience,
        s.total_plants,
        s.total_harvests,
        s.total_crops_sold,
        s.total_money_earned,
        COUNT(p.id) as current_plants,
        COUNT(CASE WHEN p.stage >= p.max_stages THEN 1 END) as ready_to_harvest,
        COUNT(CASE WHEN p.needs_water = TRUE THEN 1 END) as needs_watering,
        COUNT(CASE WHEN p.diseased = TRUE THEN 1 END) as diseased_plants
    FROM `farming_stats` s
    LEFT JOIN `farming_plants` p ON s.player_identifier = p.player_identifier
    WHERE s.player_identifier = p_identifier
    GROUP BY s.player_identifier;
END//

-- Procedure to clean up old plants (for maintenance)
CREATE PROCEDURE `CleanupOldPlants`(IN days_old INT)
BEGIN
    DELETE FROM `farming_plants` 
    WHERE created_at < DATE_SUB(NOW(), INTERVAL days_old DAY)
    AND stage >= max_stages;
    
    SELECT ROW_COUNT() as plants_removed;
END//

-- Procedure to update market prices (for dynamic economy)
CREATE PROCEDURE `UpdateMarketPrices`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE crop_name VARCHAR(50);
    DECLARE supply_count INT;
    DECLARE demand_modifier FLOAT;
    
    DECLARE crop_cursor CURSOR FOR 
        SELECT DISTINCT crop_type 
        FROM farming_plants 
        WHERE stage >= max_stages;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN crop_cursor;
    
    price_loop: LOOP
        FETCH crop_cursor INTO crop_name;
        IF done THEN
            LEAVE price_loop;
        END IF;
        
        -- Calculate supply (ready crops)
        SELECT COUNT(*) INTO supply_count
        FROM farming_plants 
        WHERE crop_type = crop_name AND stage >= max_stages;
        
        -- Calculate demand modifier based on supply
        SET demand_modifier = GREATEST(0.5, LEAST(2.0, 100.0 / (supply_count + 10)));
        
        -- Update price modifier in settings
        INSERT INTO farming_settings (setting_key, setting_value, setting_type, description)
        VALUES (CONCAT('price_modifier_', crop_name), demand_modifier, 'number', 'Dynamic price modifier')
        ON DUPLICATE KEY UPDATE setting_value = demand_modifier;
        
    END LOOP;
    
    CLOSE crop_cursor;
    
    SELECT 'Market prices updated successfully' as result;
END//

DELIMITER ;

-- Optional: Create farming leaderboards view
CREATE OR REPLACE VIEW `farming_leaderboards` AS
SELECT 
    player_identifier,
    level,
    experience,
    total_plants,
    total_harvests,
    total_crops_sold,
    total_money_earned,
    RANK() OVER (ORDER BY level DESC, experience DESC) as level_rank,
    RANK() OVER (ORDER BY total_harvests DESC) as harvest_rank,
    RANK() OVER (ORDER BY total_money_earned DESC) as money_rank
FROM farming_stats
ORDER BY level DESC, experience DESC;

-- Insert sample data for testing (remove in production)
-- INSERT INTO farming_stats (player_identifier, level, experience, total_plants, total_harvests) VALUES
-- ('license:sample123', 5, 500, 25, 15),
-- ('license:sample456', 3, 200, 12, 8),
-- ('license:sample789', 7, 800, 45, 32);

-- Success message
SELECT 'EZ Farming database setup completed successfully!' as message;
SELECT 'Tables created: farming_plants, farming_stats, farming_transactions, farming_settings' as tables_info;
SELECT 'Views created: active_plants, ready_plants, farming_leaderboards' as views_info;
SELECT 'Procedures created: GetPlayerFarmingSummary, CleanupOldPlants, UpdateMarketPrices' as procedures_info;
