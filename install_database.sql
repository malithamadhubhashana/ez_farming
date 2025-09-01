-- EZ Farming Database Setup
-- Compatible with MySQL/MariaDB
-- Execute this file in your database management tool

-- Create farming_plants table
CREATE TABLE IF NOT EXISTS `farming_plants` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_identifier` varchar(255) NOT NULL,
    `crop_type` varchar(50) NOT NULL,
    `coords_x` float NOT NULL,
    `coords_y` float NOT NULL,
    `coords_z` float NOT NULL,
    `zone_index` int(11) NOT NULL,
    `stage` int(11) DEFAULT 1,
    `max_stages` int(11) NOT NULL,
    `plant_time` bigint(20) NOT NULL,
    `last_growth_time` bigint(20) DEFAULT NULL,
    `last_water_time` bigint(20) DEFAULT NULL,
    `needs_water` tinyint(1) DEFAULT 0,
    `fertilized` tinyint(1) DEFAULT 0,
    `diseased` tinyint(1) DEFAULT 0,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_player_identifier` (`player_identifier`),
    KEY `idx_coords` (`coords_x`, `coords_y`, `coords_z`),
    KEY `idx_zone` (`zone_index`),
    KEY `idx_stage` (`stage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create farming_stats table
CREATE TABLE IF NOT EXISTS `farming_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_identifier` varchar(255) NOT NULL,
    `level` int(11) DEFAULT 1,
    `experience` int(11) DEFAULT 0,
    `total_plants` int(11) DEFAULT 0,
    `total_harvests` int(11) DEFAULT 0,
    `total_seeds_planted` int(11) DEFAULT 0,
    `total_crops_sold` int(11) DEFAULT 0,
    `total_money_earned` int(11) DEFAULT 0,
    `favorite_crop` varchar(50) DEFAULT NULL,
    `achievements` text,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `player_identifier` (`player_identifier`),
    KEY `idx_level` (`level`),
    KEY `idx_experience` (`experience`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create farming_transactions table (optional)
CREATE TABLE IF NOT EXISTS `farming_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_identifier` varchar(255) NOT NULL,
    `transaction_type` enum('buy','sell','plant','harvest') NOT NULL,
    `item_name` varchar(100) NOT NULL,
    `quantity` int(11) NOT NULL,
    `price_per_item` decimal(10,2) DEFAULT NULL,
    `total_amount` decimal(10,2) DEFAULT NULL,
    `shop_index` int(11) DEFAULT NULL,
    `zone_index` int(11) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_player_identifier` (`player_identifier`),
    KEY `idx_transaction_type` (`transaction_type`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create farming_zones table (for dynamic zones)
CREATE TABLE IF NOT EXISTS `farming_zones` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(100) NOT NULL,
    `coords_x` float NOT NULL,
    `coords_y` float NOT NULL,
    `coords_z` float NOT NULL,
    `size_x` float NOT NULL,
    `size_y` float NOT NULL,
    `size_z` float DEFAULT 2.0,
    `rotation` float DEFAULT 0.0,
    `max_plots` int(11) DEFAULT 50,
    `allowed_crops` text,
    `is_greenhouse` tinyint(1) DEFAULT 0,
    `owner_identifier` varchar(255) DEFAULT NULL,
    `price` decimal(10,2) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_coords` (`coords_x`, `coords_y`, `coords_z`),
    KEY `idx_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default farming zones (optional)
INSERT IGNORE INTO `farming_zones` (`id`, `name`, `coords_x`, `coords_y`, `coords_z`, `size_x`, `size_y`, `size_z`, `max_plots`, `allowed_crops`) VALUES
(1, 'Grapeseed Farms', 2447.24, 4961.28, 44.84, 20.0, 20.0, 2.0, 50, 'potato,tomato,corn,carrot,lettuce,wheat'),
(2, 'Paleto Bay Agriculture', -543.42, 6063.42, 30.24, 25.0, 15.0, 2.0, 35, 'potato,corn,wheat'),
(3, 'Sandy Shores Garden', 2127.86, 3328.42, 45.26, 15.0, 15.0, 2.0, 25, 'tomato,lettuce,carrot');

-- Success message
SELECT 'EZ Farming database tables created successfully!' as Status;
