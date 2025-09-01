Config = {}

-- Framework Detection (auto-detects available framework)
Config.Framework = 'auto' -- 'esx', 'qb', 'qbx', 'standalone', 'auto'

-- General Settings
Config.Debug = true
Config.UseTarget = true -- Set to false to use drawtext/markers instead of target system
Config.TargetSystem = 'auto' -- 'auto', 'ox_target', 'qb-target'
Config.DrawTextSystem = 'auto' -- 'auto', 'ox_lib', 'qb-drawtext', 'native'
Config.UseOxInventory = true -- Enable ox_inventory integration (will fallback to qb-inventory or framework inventory)
Config.MaxDistance = 2.0 -- Max distance to interact with farming zones
Config.PlantGrowthTime = 300 -- Time in seconds for plants to grow (5 minutes for testing)
Config.WateringInterval = 120 -- Time in seconds before plant needs watering again
Config.FertilizerBonus = 0.25 -- 25% faster growth with fertilizer

-- Drawtext Settings (when target systems are not available)
Config.DrawText = {
    enabled = true,
    showControls = true, -- Show key prompts
    position = 'top-center', -- ox_lib: 'top-center', 'center', etc.
    font = 0, -- GTA font ID for native drawtext
    scale = 0.35, -- Text scale for native drawtext
    color = {255, 255, 255, 255}, -- RGBA color for native drawtext
}

-- Inventory System
Config.Inventory = 'auto' -- 'auto', 'ox_inventory', 'qb-inventory', 'esx_inventoryhud'

-- Database
Config.UseDatabase = true
Config.DatabaseResource = 'mysql-async' -- 'mysql-async', 'oxmysql', 'ghmattimysql'

-- Farming Zones
Config.FarmingZones = {
    {
        name = "Grapeseed Farm",
        coords = vector3(2562.12, 4668.87, 34.08),
        size = vector3(50.0, 50.0, 10.0),
        rotation = 45.0,
        maxPlots = 20,
        allowedCrops = {'wheat', 'corn', 'tomato', 'potato', 'carrot'},
        blip = {
            enabled = true,
            sprite = 140,
            color = 2,
            scale = 0.8
        }
    },
    {
        name = "Sandy Shores Farm",
        coords = vector3(1905.42, 4925.34, 48.97),
        size = vector3(40.0, 40.0, 10.0),
        rotation = 0.0,
        maxPlots = 15,
        allowedCrops = {'wheat', 'corn', 'potato', 'carrot'},
        blip = {
            enabled = true,
            sprite = 140,
            color = 5,
            scale = 0.8
        }
    },
    {
        name = "Paleto Bay Greenhouse",
        coords = vector3(-1119.34, 2698.12, 18.55),
        size = vector3(30.0, 30.0, 8.0),
        rotation = 90.0,
        maxPlots = 12,
        allowedCrops = {'tomato', 'lettuce', 'strawberry'},
        isGreenhouse = true,
        blip = {
            enabled = true,
            sprite = 140,
            color = 3,
            scale = 0.8
        }
    }
}

-- Crop Types
Config.Crops = {
    ['wheat'] = {
        label = 'Wheat',
        seedItem = 'wheat_seed',
        harvestItem = 'wheat',
        growthStages = 4,
        growthTime = 300, -- 5 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer', 'fall'},
        minHarvest = 2,
        maxHarvest = 4,
        sellPrice = 15,
        experience = 10,
        model = 'prop_bush_lrg_01b' -- Placeholder model
    },
    ['corn'] = {
        label = 'Corn',
        seedItem = 'corn_seed',
        harvestItem = 'corn',
        growthStages = 5,
        growthTime = 360, -- 6 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer'},
        minHarvest = 1,
        maxHarvest = 3,
        sellPrice = 25,
        experience = 15,
        model = 'prop_bush_lrg_01c'
    },
    ['tomato'] = {
        label = 'Tomato',
        seedItem = 'tomato_seed',
        harvestItem = 'tomato',
        growthStages = 4,
        growthTime = 240, -- 4 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer', 'fall'},
        minHarvest = 3,
        maxHarvest = 6,
        sellPrice = 20,
        experience = 12,
        model = 'prop_bush_med_01'
    },
    ['potato'] = {
        label = 'Potato',
        seedItem = 'potato_seed',
        harvestItem = 'potato',
        growthStages = 3,
        growthTime = 420, -- 7 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'fall'},
        minHarvest = 2,
        maxHarvest = 5,
        sellPrice = 18,
        experience = 8,
        model = 'prop_bush_med_02'
    },
    ['carrot'] = {
        label = 'Carrot',
        seedItem = 'carrot_seed',
        harvestItem = 'carrot',
        growthStages = 3,
        growthTime = 300, -- 5 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer', 'fall'},
        minHarvest = 1,
        maxHarvest = 4,
        sellPrice = 22,
        experience = 9,
        model = 'prop_bush_med_03'
    },
    ['lettuce'] = {
        label = 'Lettuce',
        seedItem = 'lettuce_seed',
        harvestItem = 'lettuce',
        growthStages = 3,
        growthTime = 180, -- 3 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = false,
        seasons = {'spring', 'fall', 'winter'},
        minHarvest = 1,
        maxHarvest = 2,
        sellPrice = 12,
        experience = 6,
        model = 'prop_bush_med_04'
    },
    ['strawberry'] = {
        label = 'Strawberry',
        seedItem = 'strawberry_seed',
        harvestItem = 'strawberry',
        growthStages = 4,
        growthTime = 480, -- 8 minutes per stage
        waterNeeded = true,
        fertilizerCompatible = true,
        seasons = {'spring', 'summer'},
        minHarvest = 5,
        maxHarvest = 10,
        sellPrice = 8,
        experience = 18,
        model = 'prop_bush_lrg_02'
    }
}

-- Tools and Items
Config.Tools = {
    ['hoe'] = {
        label = 'Hoe',
        item = 'farming_hoe',
        required = true,
        durability = 100,
        repairItem = 'steel'
    },
    ['watering_can'] = {
        label = 'Watering Can',
        item = 'watering_can',
        required = true,
        capacity = 10,
        refillItem = 'water'
    },
    ['fertilizer'] = {
        label = 'Fertilizer',
        item = 'fertilizer',
        required = false,
        uses = 5
    }
}

-- Farming Shop
Config.Shops = {
    {
        name = "Farming Supply Store",
        coords = vector3(2557.42, 4668.12, 34.08),
        ped = {
            model = 'a_m_m_farmer_01',
            coords = vector3(2557.42, 4668.12, 33.08),
            heading = 90.0
        },
        items = {
            -- Seeds
            {item = 'wheat_seed', price = 5, stock = 100},
            {item = 'corn_seed', price = 8, stock = 100},
            {item = 'tomato_seed', price = 6, stock = 100},
            {item = 'potato_seed', price = 7, stock = 100},
            {item = 'carrot_seed', price = 6, stock = 100},
            {item = 'lettuce_seed', price = 4, stock = 100},
            {item = 'strawberry_seed', price = 10, stock = 50},
            
            -- Tools
            {item = 'farming_hoe', price = 150, stock = 10},
            {item = 'watering_can', price = 75, stock = 15},
            {item = 'fertilizer', price = 25, stock = 50},
            
            -- Other
            {item = 'water', price = 2, stock = 200}
        }
    },
    {
        name = "Crop Buyer",
        coords = vector3(2540.12, 4675.89, 34.08),
        ped = {
            model = 'a_m_m_business_01',
            coords = vector3(2540.12, 4675.89, 33.08),
            heading = 180.0
        },
        sellOnly = true,
        items = {
            {item = 'wheat', price = 15},
            {item = 'corn', price = 25},
            {item = 'tomato', price = 20},
            {item = 'potato', price = 18},
            {item = 'carrot', price = 22},
            {item = 'lettuce', price = 12},
            {item = 'strawberry', price = 8}
        }
    }
}

-- Leveling System
Config.LevelSystem = {
    enabled = true,
    maxLevel = 100,
    experiencePerLevel = {
        [1] = 100,
        [2] = 250,
        [3] = 450,
        [4] = 700,
        [5] = 1000,
        -- Dynamic calculation for levels 6+
    },
    levelBonuses = {
        [5] = {type = 'harvest_bonus', value = 0.1}, -- 10% more harvest
        [10] = {type = 'growth_speed', value = 0.05}, -- 5% faster growth
        [15] = {type = 'harvest_bonus', value = 0.15}, -- Additional 5% harvest bonus
        [20] = {type = 'water_efficiency', value = 0.1}, -- 10% less water needed
        [25] = {type = 'growth_speed', value = 0.1}, -- Additional 5% growth speed
        [30] = {type = 'harvest_bonus', value = 0.2}, -- Additional 5% harvest bonus
        -- Continue pattern...
    }
}

-- Weather Effects
Config.Weather = {
    enabled = true,
    effects = {
        ['RAIN'] = {growth_bonus = 0.1, water_bonus = 0.5},
        ['THUNDER'] = {growth_bonus = 0.05, water_bonus = 0.3},
        ['SUNNY'] = {growth_penalty = 0.05, water_penalty = 0.2},
        ['CLEAR'] = {growth_bonus = 0.02},
        ['OVERCAST'] = {water_bonus = 0.1},
        ['FOGGY'] = {growth_penalty = 0.1}
    }
}

-- Season System
Config.Seasons = {
    enabled = true,
    currentSeason = 'spring', -- Will be dynamic in real implementation
    duration = 7200, -- Season duration in seconds (2 hours)
    effects = {
        ['spring'] = {growth_bonus = 0.1, all_crops = true},
        ['summer'] = {growth_bonus = 0.05, water_penalty = 0.1},
        ['fall'] = {harvest_bonus = 0.1, growth_penalty = 0.05},
        ['winter'] = {growth_penalty = 0.2, greenhouse_bonus = 0.15}
    }
}

-- Notifications
Config.Notifications = {
    ['plant_success'] = {
        title = 'Farming',
        message = 'Successfully planted %s!',
        type = 'success',
        duration = 3000
    },
    ['harvest_success'] = {
        title = 'Farming',
        message = 'Harvested %s x%d!',
        type = 'success',
        duration = 3000
    },
    ['water_success'] = {
        title = 'Farming',
        message = 'Plant watered successfully!',
        type = 'success',
        duration = 3000
    },
    ['fertilize_success'] = {
        title = 'Farming',
        message = 'Plant fertilized successfully!',
        type = 'success',
        duration = 3000
    },
    ['no_seeds'] = {
        title = 'Farming',
        message = 'You don\'t have any seeds to plant!',
        type = 'error',
        duration = 3000
    },
    ['no_tool'] = {
        title = 'Farming',
        message = 'You need a %s to do that!',
        type = 'error',
        duration = 3000
    },
    ['plot_occupied'] = {
        title = 'Farming',
        message = 'This plot is already occupied!',
        type = 'error',
        duration = 3000
    },
    ['not_ready'] = {
        title = 'Farming',
        message = 'This plant is not ready to harvest yet!',
        type = 'error',
        duration = 3000
    },
    ['level_up'] = {
        title = 'Farming Level Up!',
        message = 'You reached level %d in farming!',
        type = 'success',
        duration = 5000
    }
}

-- Command Settings
Config.Commands = {
    ['farming_admin'] = {
        enabled = true,
        command = 'farmingadmin',
        permission = 'admin', -- ESX: group, QB/QBX: permission
        help = 'Open farming admin menu'
    },
    ['farming_stats'] = {
        enabled = true,
        command = 'farmstats',
        permission = nil,
        help = 'Check your farming statistics'
    }
}
