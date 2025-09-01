local QBCore, ESX, QBX = nil, nil, nil
local Framework = nil
local PlantedCrops = {}
local PlayerStats = {}

-- Framework Detection and Initialization
CreateThread(function()
    if Config.Framework == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            ESX = exports['es_extended']:getSharedObject()
        elseif GetResourceState('qbx_core') == 'started' then
            Framework = 'qbx'
            -- QBX doesn't need a core object like QB-Core
        elseif GetResourceState('qb-core') == 'started' then
            Framework = 'qb'
            QBCore = exports['qb-core']:GetCoreObject()
        else
            Framework = 'standalone'
        end
    else
        Framework = Config.Framework
        if Framework == 'esx' then
            ESX = exports['es_extended']:getSharedObject()
        elseif Framework == 'qbx' then
            -- QBX doesn't need core object initialization
        elseif Framework == 'qb' then
            QBCore = exports['qb-core']:GetCoreObject()
        end
    end
    
    print('^2[EZ Farming]^7 Server initialized with framework: ' .. Framework)
    
    -- Initialize database
    if Config.UseDatabase then
        InitializeDatabase()
    end
    
    -- Load existing data
    LoadPlantedCrops()
    
    -- Start automated systems
    StartWeatherSystem()
    StartSeasonSystem()
end)

-- Database Functions
function InitializeDatabase()
    if not Config.UseDatabase then return end
    
    local queries = {
        [[
        CREATE TABLE IF NOT EXISTS farming_plants (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_identifier VARCHAR(255) NOT NULL,
            crop_type VARCHAR(50) NOT NULL,
            coords_x FLOAT NOT NULL,
            coords_y FLOAT NOT NULL,
            coords_z FLOAT NOT NULL,
            zone_index INT NOT NULL,
            stage INT DEFAULT 1,
            max_stages INT NOT NULL,
            plant_time BIGINT NOT NULL,
            last_growth_time BIGINT,
            last_water_time BIGINT,
            needs_water BOOLEAN DEFAULT FALSE,
            fertilized BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ]],
        [[
        CREATE TABLE IF NOT EXISTS farming_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_identifier VARCHAR(255) UNIQUE NOT NULL,
            level INT DEFAULT 1,
            experience INT DEFAULT 0,
            total_plants INT DEFAULT 0,
            total_harvests INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
        ]]
    }
    
    for _, query in ipairs(queries) do
        if Config.DatabaseResource == 'mysql-async' then
            MySQL.Async.execute(query, {})
        elseif Config.DatabaseResource == 'oxmysql' then
            exports.oxmysql:execute(query, {})
        elseif Config.DatabaseResource == 'ghmattimysql' then
            exports.ghmattimysql:execute(query, {})
        end
    end
    
    print('^2[EZ Farming]^7 Database tables initialized')
end

function LoadPlantedCrops()
    if not Config.UseDatabase then return end
    
    local query = "SELECT * FROM farming_plants"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.fetchAll(query, {}, function(result)
            ProcessLoadedCrops(result)
        end)
    elseif Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, {}, function(result)
            ProcessLoadedCrops(result)
        end)
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, {}, function(result)
            ProcessLoadedCrops(result)
        end)
    end
end

function ProcessLoadedCrops(crops)
    PlantedCrops = {}
    for _, crop in ipairs(crops) do
        PlantedCrops[crop.id] = {
            id = crop.id,
            playerIdentifier = crop.player_identifier,
            cropType = crop.crop_type,
            coords = vector3(crop.coords_x, crop.coords_y, crop.coords_z),
            zoneIndex = crop.zone_index,
            stage = crop.stage,
            maxStages = crop.max_stages,
            plantTime = crop.plant_time,
            lastGrowthTime = crop.last_growth_time,
            lastWaterTime = crop.last_water_time,
            needsWater = crop.needs_water == 1,
            fertilized = crop.fertilized == 1
        }
    end
    print('^2[EZ Farming]^7 Loaded ' .. #crops .. ' planted crops from database')
end

function SavePlantToDatabase(plantData)
    if not Config.UseDatabase then return end
    
    local query = [[
        INSERT INTO farming_plants 
        (player_identifier, crop_type, coords_x, coords_y, coords_z, zone_index, 
         stage, max_stages, plant_time, needs_water, fertilized)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    local params = {
        plantData.playerIdentifier,
        plantData.cropType,
        plantData.coords.x,
        plantData.coords.y,
        plantData.coords.z,
        plantData.zoneIndex,
        plantData.stage,
        plantData.maxStages,
        plantData.plantTime,
        plantData.needsWater,
        plantData.fertilized
    }
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.insert(query, params, function(insertId)
            plantData.id = insertId
            PlantedCrops[insertId] = plantData
        end)
    elseif Config.DatabaseResource == 'oxmysql' then
        local insertId = exports.oxmysql:insert_async(query, params)
        plantData.id = insertId
        PlantedCrops[insertId] = plantData
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, params, function(result)
            plantData.id = result.insertId
            PlantedCrops[result.insertId] = plantData
        end)
    end
end

function UpdatePlantInDatabase(plantId, updates)
    if not Config.UseDatabase then return end
    
    local setParts = {}
    local params = {}
    
    for key, value in pairs(updates) do
        table.insert(setParts, key .. " = ?")
        table.insert(params, value)
    end
    
    table.insert(params, plantId)
    
    local query = "UPDATE farming_plants SET " .. table.concat(setParts, ", ") .. " WHERE id = ?"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.execute(query, params)
    elseif Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, params)
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, params)
    end
end

function RemovePlantFromDatabase(plantId)
    if not Config.UseDatabase then return end
    
    local query = "DELETE FROM farming_plants WHERE id = ?"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.execute(query, {plantId})
    elseif Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, {plantId})
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, {plantId})
    end
end

-- Player Stats Functions
function LoadPlayerStats(identifier)
    if not Config.UseDatabase then
        PlayerStats[identifier] = {
            level = 1,
            experience = 0,
            totalPlants = 0,
            totalHarvests = 0
        }
        return
    end
    
    local query = "SELECT * FROM farming_stats WHERE player_identifier = ?"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.fetchAll(query, {identifier}, function(result)
            if result[1] then
                PlayerStats[identifier] = result[1]
            else
                -- Create new player stats
                CreatePlayerStats(identifier)
            end
        end)
    elseif Config.DatabaseResource == 'oxmysql' then
        local result = exports.oxmysql:execute_sync(query, {identifier})
        if result[1] then
            PlayerStats[identifier] = result[1]
        else
            CreatePlayerStats(identifier)
        end
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, {identifier}, function(result)
            if result[1] then
                PlayerStats[identifier] = result[1]
            else
                CreatePlayerStats(identifier)
            end
        end)
    end
end

function CreatePlayerStats(identifier)
    PlayerStats[identifier] = {
        level = 1,
        experience = 0,
        totalPlants = 0,
        totalHarvests = 0
    }
    
    if not Config.UseDatabase then return end
    
    local query = "INSERT INTO farming_stats (player_identifier) VALUES (?)"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.execute(query, {identifier})
    elseif Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, {identifier})
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, {identifier})
    end
end

function UpdatePlayerStats(identifier, updates)
    if not PlayerStats[identifier] then
        LoadPlayerStats(identifier)
        return
    end
    
    for key, value in pairs(updates) do
        PlayerStats[identifier][key] = value
    end
    
    if not Config.UseDatabase then return end
    
    local setParts = {}
    local params = {}
    
    for key, value in pairs(updates) do
        table.insert(setParts, key .. " = ?")
        table.insert(params, value)
    end
    
    table.insert(params, identifier)
    
    local query = "UPDATE farming_stats SET " .. table.concat(setParts, ", ") .. " WHERE player_identifier = ?"
    
    if Config.DatabaseResource == 'mysql-async' then
        MySQL.Async.execute(query, params)
    elseif Config.DatabaseResource == 'oxmysql' then
        exports.oxmysql:execute(query, params)
    elseif Config.DatabaseResource == 'ghmattimysql' then
        exports.ghmattimysql:execute(query, params)
    end
end

function AddExperience(identifier, amount)
    if not PlayerStats[identifier] then
        LoadPlayerStats(identifier)
        Wait(100) -- Small delay for async loading
    end
    
    local stats = PlayerStats[identifier]
    if not stats then return end
    
    local oldLevel = stats.level
    stats.experience = (stats.experience or 0) + amount
    
    -- Check for level up
    local newLevel = CalculateLevel(stats.experience)
    if newLevel > oldLevel then
        stats.level = newLevel
        UpdatePlayerStats(identifier, {level = newLevel, experience = stats.experience})
        
        -- Notify player of level up
        local player = GetPlayerByIdentifier(identifier)
        if player then
            TriggerClientEvent('ez_farming:levelUp', player, newLevel)
        end
        
        -- Apply level bonuses
        ApplyLevelBonuses(identifier, newLevel)
    else
        UpdatePlayerStats(identifier, {experience = stats.experience})
    end
end

function CalculateLevel(experience)
    local level = 1
    local totalExp = 0
    
    for i = 1, Config.LevelSystem.maxLevel do
        local expNeeded = Config.LevelSystem.experiencePerLevel[i] or (100 * math.pow(1.1, i - 1))
        totalExp = totalExp + expNeeded
        
        if experience >= totalExp then
            level = i + 1
        else
            break
        end
    end
    
    return math.min(level, Config.LevelSystem.maxLevel)
end

function ApplyLevelBonuses(identifier, level)
    local bonus = Config.LevelSystem.levelBonuses[level]
    if bonus then
        print('^2[EZ Farming]^7 Player ' .. identifier .. ' reached level ' .. level .. ' and received bonus: ' .. bonus.type)
        -- Implement bonus effects here
    end
end

-- Utility Functions
function GetPlayerByIdentifier(identifier)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdentifier = GetPlayerIdentifierByType(playerId, 'license') or GetPlayerIdentifierByType(playerId, 'steam')
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

function GetPlayerIdentifier(playerId)
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        return xPlayer and xPlayer.identifier or nil
    elseif Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(playerId)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(playerId)
        return Player and Player.PlayerData.citizenid or nil
    else
        return GetPlayerIdentifierByType(playerId, 'license') or GetPlayerIdentifierByType(playerId, 'steam') or tostring(playerId)
    end
end

function GetPlayerFromId(playerId)
    if Framework == 'esx' then
        return ESX.GetPlayerFromId(playerId)
    elseif Framework == 'qb' then
        return QBCore.Functions.GetPlayer(playerId)
    elseif Framework == 'qbx' then
        return exports.qbx_core:GetPlayer(playerId)
    else
        return {source = playerId} -- Standalone fallback
    end
end

function HasItem(playerId, item, amount)
    amount = amount or 1
    local Player = GetPlayerFromId(playerId)
    if not Player then return false end
    
    -- Check if using ox_inventory
    if Config.UseOxInventory and GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search(playerId, 'count', item)
        return count >= amount
    elseif Framework == 'esx' then
        local itemCount = Player.getInventoryItem(item)
        return itemCount and itemCount.count >= amount
    elseif Framework == 'qb' or Framework == 'qbx' then
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= amount
    else
        -- Standalone - implement your own inventory check
        return true -- Placeholder
    end
end

function RemoveItem(playerId, item, amount)
    amount = amount or 1
    local Player = GetPlayerFromId(playerId)
    if not Player then return false end
    
    -- Check if using ox_inventory
    if Config.UseOxInventory and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(playerId, item, amount)
    elseif Framework == 'esx' then
        Player.removeInventoryItem(item, amount)
        return true
    elseif Framework == 'qb' or Framework == 'qbx' then
        return Player.Functions.RemoveItem(item, amount)
    else
        -- Standalone - implement your own inventory removal
        return true
    end
end

function AddItem(playerId, item, amount, metadata)
    amount = amount or 1
    local Player = GetPlayerFromId(playerId)
    if not Player then return false end
    
    -- Check if using ox_inventory first
    if Config.UseOxInventory and exports.ox_inventory then
        return exports.ox_inventory:AddItem(playerId, item, amount, metadata)
    elseif Framework == 'esx' then
        Player.addInventoryItem(item, amount)
        return true
    elseif Framework == 'qb' then
        return Player.Functions.AddItem(item, amount, false, metadata)
    elseif Framework == 'qbx' then
        -- QBX uses ox_inventory by default
        return exports.ox_inventory:AddItem(playerId, item, amount, metadata)
    else
        -- Standalone - implement your own inventory addition
        return true
    end
end

function AddMoney(playerId, amount)
    local Player = GetPlayerFromId(playerId)
    if not Player then return false end
    
    if Framework == 'esx' then
        Player.addMoney(amount)
        return true
    elseif Framework == 'qb' or Framework == 'qbx' then
        return Player.Functions.AddMoney('cash', amount)
    else
        -- Standalone - implement your own money system
        return true
    end
end

function RemoveMoney(playerId, amount)
    local Player = GetPlayerFromId(playerId)
    if not Player then return false end
    
    if Framework == 'esx' then
        return Player.removeMoney(amount)
    elseif Framework == 'qb' or Framework == 'qbx' then
        return Player.Functions.RemoveMoney('cash', amount)
    else
        -- Standalone - implement your own money system
        return true
    end
end

-- Weather and Season Systems
function StartWeatherSystem()
    if not Config.Weather.enabled then return end
    
    CreateThread(function()
        while true do
            Wait(60000) -- Check every minute
            
            local currentWeather = GetCurrentWeather()
            local effects = Config.Weather.effects[currentWeather]
            
            if effects then
                -- Apply weather effects to all plants
                for plantId, plant in pairs(PlantedCrops) do
                    if effects.growth_bonus and plant.stage < plant.maxStages then
                        -- Weather bonus logic would go here
                    end
                    
                    if effects.water_bonus and plant.needsWater then
                        -- Reduce water need due to rain
                        plant.needsWater = false
                        UpdatePlantInDatabase(plantId, {needs_water = false})
                        TriggerClientEvent('ez_farming:waterSuccess', -1, plantId)
                    end
                end
            end
        end
    end)
end

function StartSeasonSystem()
    if not Config.Seasons.enabled then return end
    
    CreateThread(function()
        while true do
            Wait(Config.Seasons.duration * 1000) -- Season duration
            
            -- Cycle through seasons
            local seasons = {'spring', 'summer', 'fall', 'winter'}
            local currentIndex = 1
            
            for i, season in ipairs(seasons) do
                if season == Config.Seasons.currentSeason then
                    currentIndex = i
                    break
                end
            end
            
            local nextIndex = (currentIndex % #seasons) + 1
            Config.Seasons.currentSeason = seasons[nextIndex]
            
            print('^2[EZ Farming]^7 Season changed to: ' .. Config.Seasons.currentSeason)
            TriggerClientEvent('ez_farming:seasonChanged', -1, Config.Seasons.currentSeason)
        end
    end)
end

function GetCurrentWeather()
    -- This would integrate with your server's weather system
    -- For now, return a random weather type
    local weatherTypes = {'SUNNY', 'CLEAR', 'RAIN', 'THUNDER', 'OVERCAST', 'FOGGY'}
    return weatherTypes[math.random(#weatherTypes)]
end

-- Event Handlers
RegisterNetEvent('ez_farming:playerLoaded')
AddEventHandler('ez_farming:playerLoaded', function()
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    
    LoadPlayerStats(identifier)
    TriggerClientEvent('ez_farming:updatePlantedCrops', playerId, PlantedCrops)
end)

RegisterNetEvent('ez_farming:requestPlantedCrops')
AddEventHandler('ez_farming:requestPlantedCrops', function()
    local playerId = source
    TriggerClientEvent('ez_farming:updatePlantedCrops', playerId, PlantedCrops)
end)

RegisterNetEvent('ez_farming:plantCrop')
AddEventHandler('ez_farming:plantCrop', function(data)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    
    -- Validate player has seeds and tools
    local cropConfig = Config.Crops[data.cropType]
    if not HasItem(playerId, cropConfig.seedItem) or not HasItem(playerId, Config.Tools.hoe.item) then
        return
    end
    
    -- Check zone capacity
    local zone = Config.FarmingZones[data.zoneIndex]
    local plantsInZone = 0
    for _, plant in pairs(PlantedCrops) do
        if plant.zoneIndex == data.zoneIndex then
            plantsInZone = plantsInZone + 1
        end
    end
    
    if plantsInZone >= zone.maxPlots then
        TriggerClientEvent('ez_farming:notify', playerId, 'Zone is full!')
        return
    end
    
    -- Remove seed from inventory
    if not RemoveItem(playerId, cropConfig.seedItem, 1) then
        return
    end
    
    -- Create plant data
    local plantData = {
        playerIdentifier = identifier,
        cropType = data.cropType,
        coords = data.coords,
        zoneIndex = data.zoneIndex,
        stage = 1,
        maxStages = cropConfig.growthStages,
        plantTime = os.time() * 1000,
        lastGrowthTime = nil,
        lastWaterTime = os.time() * 1000,
        needsWater = false,
        fertilized = false
    }
    
    -- Save to database and add to memory
    SavePlantToDatabase(plantData)
    
    -- Update player stats
    if not PlayerStats[identifier] then
        LoadPlayerStats(identifier)
    end
    
    if PlayerStats[identifier] then
        PlayerStats[identifier].totalPlants = (PlayerStats[identifier].totalPlants or 0) + 1
        UpdatePlayerStats(identifier, {total_plants = PlayerStats[identifier].totalPlants})
    end
    
    AddExperience(identifier, 5) -- Base XP for planting
    
    -- Notify all clients
    TriggerClientEvent('ez_farming:plantSuccess', -1, plantData)
end)

RegisterNetEvent('ez_farming:harvestCrop')
AddEventHandler('ez_farming:harvestCrop', function(plantId)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    local plant = PlantedCrops[plantId]
    
    if not plant or plant.stage < plant.maxStages then
        return
    end
    
    -- Check if player owns the plant or has permission
    if plant.playerIdentifier ~= identifier then
        -- Add admin check or shared farming logic here
        return
    end
    
    -- Check if player has harvesting tool
    if not HasItem(playerId, Config.Tools.hoe.item) then
        return
    end
    
    local cropConfig = Config.Crops[plant.cropType]
    local harvestAmount = math.random(cropConfig.minHarvest, cropConfig.maxHarvest)
    
    -- Apply level bonuses
    local stats = PlayerStats[identifier]
    if stats and stats.level then
        local harvestBonus = 0
        for level, bonus in pairs(Config.LevelSystem.levelBonuses) do
            if level <= stats.level and bonus.type == 'harvest_bonus' then
                harvestBonus = harvestBonus + bonus.value
            end
        end
        
        harvestAmount = math.floor(harvestAmount * (1 + harvestBonus))
    end
    
    -- Add harvested items to player inventory
    if AddItem(playerId, cropConfig.harvestItem, harvestAmount) then
        -- Remove plant from database and memory
        RemovePlantFromDatabase(plantId)
        PlantedCrops[plantId] = nil
        
        -- Update player stats
        if PlayerStats[identifier] then
            PlayerStats[identifier].totalHarvests = (PlayerStats[identifier].totalHarvests or 0) + 1
            UpdatePlayerStats(identifier, {total_harvests = PlayerStats[identifier].totalHarvests})
        end
        
        AddExperience(identifier, cropConfig.experience)
        
        -- Notify clients
        TriggerClientEvent('ez_farming:harvestSuccess', -1, plantId, {
            cropType = plant.cropType,
            amount = harvestAmount
        })
    end
end)

RegisterNetEvent('ez_farming:waterPlant')
AddEventHandler('ez_farming:waterPlant', function(plantId)
    local playerId = source
    local plant = PlantedCrops[plantId]
    
    if not plant or not plant.needsWater then
        return
    end
    
    -- Check if player has watering can
    if not HasItem(playerId, Config.Tools.watering_can.item) then
        return
    end
    
    -- Update plant
    plant.needsWater = false
    plant.lastWaterTime = os.time() * 1000
    
    UpdatePlantInDatabase(plantId, {
        needs_water = false,
        last_water_time = plant.lastWaterTime
    })
    
    -- Notify clients
    TriggerClientEvent('ez_farming:waterSuccess', -1, plantId)
end)

RegisterNetEvent('ez_farming:fertilizePlant')
AddEventHandler('ez_farming:fertilizePlant', function(plantId)
    local playerId = source
    local plant = PlantedCrops[plantId]
    
    if not plant or plant.fertilized then
        return
    end
    
    local cropConfig = Config.Crops[plant.cropType]
    if not cropConfig.fertilizerCompatible then
        return
    end
    
    -- Check if player has fertilizer
    if not HasItem(playerId, Config.Tools.fertilizer.item) then
        return
    end
    
    -- Remove fertilizer from inventory
    if not RemoveItem(playerId, Config.Tools.fertilizer.item, 1) then
        return
    end
    
    -- Update plant
    plant.fertilized = true
    
    UpdatePlantInDatabase(plantId, {fertilized = true})
    
    -- Notify clients
    TriggerClientEvent('ez_farming:fertilizeSuccess', -1, plantId)
end)

RegisterNetEvent('ez_farming:growPlant')
AddEventHandler('ez_farming:growPlant', function(plantId)
    local plant = PlantedCrops[plantId]
    if not plant or plant.stage >= plant.maxStages then
        return
    end
    
    -- Check if plant needs water
    local cropConfig = Config.Crops[plant.cropType]
    if cropConfig.waterNeeded and plant.needsWater then
        return -- Can't grow without water
    end
    
    -- Grow the plant
    plant.stage = plant.stage + 1
    plant.lastGrowthTime = os.time() * 1000
    
    UpdatePlantInDatabase(plantId, {
        stage = plant.stage,
        last_growth_time = plant.lastGrowthTime
    })
    
    -- Notify clients
    TriggerClientEvent('ez_farming:plantGrown', -1, plantId, plant.stage)
end)

RegisterNetEvent('ez_farming:updatePlantWater')
AddEventHandler('ez_farming:updatePlantWater', function(plantId, needsWater)
    local plant = PlantedCrops[plantId]
    if plant then
        plant.needsWater = needsWater
        UpdatePlantInDatabase(plantId, {needs_water = needsWater})
    end
end)

RegisterNetEvent('ez_farming:getPlayerStats')
AddEventHandler('ez_farming:getPlayerStats', function()
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    
    if not PlayerStats[identifier] then
        LoadPlayerStats(identifier)
        Wait(100)
    end
    
    TriggerClientEvent('ez_farming:showPlayerStats', playerId, PlayerStats[identifier] or {})
end)

-- Shop Events
RegisterNetEvent('ez_farming:buyItem')
AddEventHandler('ez_farming:buyItem', function(shopIndex, itemName, amount)
    local playerId = source
    local shop = Config.Shops[shopIndex]
    if not shop then return end
    
    local itemConfig = nil
    for _, item in ipairs(shop.items) do
        if item.item == itemName then
            itemConfig = item
            break
        end
    end
    
    if not itemConfig then return end
    
    local totalPrice = itemConfig.price * amount
    
    -- Check if player has enough money
    local Player = GetPlayerFromId(playerId)
    local hasMoney = false
    
    if Framework == 'esx' then
        hasMoney = Player.getMoney() >= totalPrice
    elseif Framework == 'qb' or Framework == 'qbx' then
        hasMoney = Player.PlayerData.money.cash >= totalPrice
    else
        hasMoney = true -- Standalone
    end
    
    if not hasMoney then
        TriggerClientEvent('ez_farming:notify', playerId, 'Not enough money!')
        return
    end
    
    -- Remove money and add item
    if RemoveMoney(playerId, totalPrice) then
        if AddItem(playerId, itemName, amount) then
            TriggerClientEvent('ez_farming:notify', playerId, 'Purchase successful!')
        end
    end
end)

RegisterNetEvent('ez_farming:sellItem')
AddEventHandler('ez_farming:sellItem', function(shopIndex, itemName, amount)
    local playerId = source
    local shop = Config.Shops[shopIndex]
    if not shop or not shop.sellOnly then return end
    
    local itemConfig = nil
    for _, item in ipairs(shop.items) do
        if item.item == itemName then
            itemConfig = item
            break
        end
    end
    
    if not itemConfig then return end
    
    -- Check if player has the item
    if not HasItem(playerId, itemName, amount) then
        TriggerClientEvent('ez_farming:notify', playerId, 'You don\'t have enough items to sell!')
        return
    end
    
    local totalPrice = itemConfig.price * amount
    
    -- Remove item and add money
    if RemoveItem(playerId, itemName, amount) then
        if AddMoney(playerId, totalPrice) then
            TriggerClientEvent('ez_farming:notify', playerId, 'Sale successful! Earned $' .. totalPrice)
        end
    end
end)

-- Admin Commands
if Config.Commands.farming_admin.enabled then
    RegisterCommand(Config.Commands.farming_admin.command, function(source, args, rawCommand)
        local playerId = source
        
        -- Check permissions
        local hasPermission = false
        if Framework == 'esx' then
            local xPlayer = ESX.GetPlayerFromId(playerId)
            hasPermission = xPlayer.getGroup() == Config.Commands.farming_admin.permission
        elseif Framework == 'qb' or Framework == 'qbx' then
            local Player = GetPlayerFromId(playerId)
            hasPermission = Player.PlayerData.job.name == 'admin' or 
                           (QBCore and QBCore.Functions.HasPermission(playerId, Config.Commands.farming_admin.permission))
        else
            hasPermission = true -- Standalone
        end
        
        if not hasPermission then
            TriggerClientEvent('ez_farming:notify', playerId, 'No permission!')
            return
        end
        
        -- Open admin menu
        TriggerClientEvent('ez_farming:openAdminMenu', playerId)
    end, false)
end

-- Cleanup
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    
    -- Save any pending data
    if PlayerStats[identifier] then
        -- Data is already saved to database in real-time
    end
end)

print('^2[EZ Farming]^7 Server script loaded successfully!')
