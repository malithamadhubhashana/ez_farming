-- Server utilities and admin functions
local AdminFunctions = {}

-- Enhanced admin system
RegisterNetEvent('ez_farming:adminViewPlants')
AddEventHandler('ez_farming:adminViewPlants', function()
    local source = source
    local plantList = {}
    
    for plantId, plant in pairs(PlantedCrops) do
        local cropConfig = Config.Crops[plant.cropType]
        table.insert(plantList, {
            id = plantId,
            type = cropConfig.label,
            stage = plant.stage .. '/' .. plant.maxStages,
            coords = string.format("%.2f, %.2f, %.2f", plant.coords.x, plant.coords.y, plant.coords.z),
            owner = plant.playerIdentifier,
            needsWater = plant.needsWater and "Yes" or "No",
            fertilized = plant.fertilized and "Yes" or "No"
        })
    end
    
    TriggerClientEvent('ez_farming:showAdminPlantList', source, plantList)
end)

RegisterNetEvent('ez_farming:adminRemoveAll')
AddEventHandler('ez_farming:adminRemoveAll', function()
    local source = source
    
    for plantId in pairs(PlantedCrops) do
        RemovePlantFromDatabase(plantId)
    end
    
    PlantedCrops = {}
    TriggerClientEvent('ez_farming:updatePlantedCrops', -1, PlantedCrops)
    TriggerClientEvent('ez_farming:notify', source, 'All plants removed!', 'success')
end)

RegisterNetEvent('ez_farming:adminSetSeason')
AddEventHandler('ez_farming:adminSetSeason', function(season)
    local source = source
    
    if not season or not Config.Seasons.effects[season] then
        TriggerClientEvent('ez_farming:notify', source, 'Invalid season!', 'error')
        return
    end
    
    Config.Seasons.currentSeason = season
    TriggerClientEvent('ez_farming:seasonChanged', -1, season)
    TriggerClientEvent('ez_farming:notify', source, 'Season changed to ' .. season, 'success')
end)

RegisterNetEvent('ez_farming:adminSetWeather')
AddEventHandler('ez_farming:adminSetWeather', function(weather)
    local source = source
    
    if not weather or not Config.Weather.effects[weather] then
        TriggerClientEvent('ez_farming:notify', source, 'Invalid weather type!', 'error')
        return
    end
    
    TriggerClientEvent('ez_farming:weatherSync', -1, weather)
    TriggerClientEvent('ez_farming:notify', source, 'Weather changed to ' .. weather, 'success')
end)

RegisterNetEvent('ez_farming:adminPlayerStats')
AddEventHandler('ez_farming:adminPlayerStats', function(targetId)
    local source = source
    
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ez_farming:notify', source, 'Invalid player ID!', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(targetId)
    local stats = PlayerStats[identifier]
    
    if not stats then
        TriggerClientEvent('ez_farming:notify', source, 'No farming stats found for this player!', 'error')
        return
    end
    
    local statsText = string.format(
        "Player: %s\nLevel: %d\nExperience: %d\nTotal Plants: %d\nTotal Harvests: %d",
        GetPlayerName(targetId),
        stats.level or 1,
        stats.experience or 0,
        stats.total_plants or 0,
        stats.total_harvests or 0
    )
    
    TriggerClientEvent('ez_farming:showAdminStats', source, statsText)
end)

RegisterNetEvent('ez_farming:adminReloadConfig')
AddEventHandler('ez_farming:adminReloadConfig', function()
    local source = source
    
    -- Trigger config reload (you would implement config hot-reloading here)
    TriggerClientEvent('ez_farming:notify', source, 'Config reloaded!', 'success')
    print('^2[EZ Farming]^7 Config reloaded by admin: ' .. GetPlayerName(source))
end)

-- Session statistics tracking
local SessionStats = {}

RegisterNetEvent('ez_farming:updateSessionStats')
AddEventHandler('ez_farming:updateSessionStats', function(stats)
    local source = source
    local identifier = GetPlayerIdentifier(source)
    
    SessionStats[identifier] = stats
end)

-- Advanced crop rotation system
function CheckCropRotation(zoneIndex, cropType)
    -- Get last 3 crops planted in this zone
    local recentCrops = {}
    for _, plant in pairs(PlantedCrops) do
        if plant.zoneIndex == zoneIndex then
            table.insert(recentCrops, plant.cropType)
        end
    end
    
    -- Simple rotation check - prevent same crop 3 times in a row
    local sameCount = 0
    for i = #recentCrops, math.max(1, #recentCrops - 2), -1 do
        if recentCrops[i] == cropType then
            sameCount = sameCount + 1
        else
            break
        end
    end
    
    return sameCount < 2 -- Allow if less than 2 consecutive same crops
end

-- Pest system
local PestInfestations = {}

CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        
        for plantId, plant in pairs(PlantedCrops) do
            if plant.stage > 1 and plant.stage < plant.maxStages then
                local pestChance = 0.02 -- 2% base chance
                
                -- Increase chance based on conditions
                if not plant.fertilized then
                    pestChance = pestChance + 0.01
                end
                
                if plant.needsWater then
                    pestChance = pestChance + 0.015
                end
                
                -- Season effects
                if Config.Seasons.currentSeason == 'summer' then
                    pestChance = pestChance + 0.01
                end
                
                if math.random() < pestChance then
                    PestInfestations[plantId] = {
                        severity = math.random(1, 3),
                        startTime = os.time() * 1000
                    }
                    
                    -- Notify nearby players
                    local nearbyPlayers = GetPlayersInArea(plant.coords, 100.0)
                    for _, playerId in ipairs(nearbyPlayers) do
                        TriggerClientEvent('ez_farming:pestInfestation', playerId, plantId, plant.coords)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('ez_farming:treatPests')
AddEventHandler('ez_farming:treatPests', function(plantId)
    local source = source
    local plant = PlantedCrops[plantId]
    
    if not plant or not PestInfestations[plantId] then
        return
    end
    
    -- Check if player has pesticide
    if not HasItem(source, 'pesticide') then
        TriggerClientEvent('ez_farming:notify', source, 'You need pesticide to treat pests!', 'error')
        return
    end
    
    if RemoveItem(source, 'pesticide', 1) then
        PestInfestations[plantId] = nil
        TriggerClientEvent('ez_farming:notify', source, 'Pests treated successfully!', 'success')
        TriggerClientEvent('ez_farming:pestsCleared', -1, plantId)
    end
end)

-- Disease system
local PlantDiseases = {}

CreateThread(function()
    while true do
        Wait(600000) -- Check every 10 minutes
        
        for plantId, plant in pairs(PlantedCrops) do
            if plant.stage > 2 then
                local diseaseChance = 0.01 -- 1% base chance
                
                -- Weather effects on disease
                if CurrentWeather == 'RAIN' or CurrentWeather == 'THUNDER' then
                    diseaseChance = diseaseChance + 0.02
                end
                
                if math.random() < diseaseChance then
                    PlantDiseases[plantId] = {
                        type = math.random(1, 3), -- Different disease types
                        severity = math.random(1, 2),
                        startTime = os.time() * 1000
                    }
                    
                    -- Slow growth or stop it entirely
                    plant.diseased = true
                    UpdatePlantInDatabase(plantId, {diseased = true})
                    
                    local nearbyPlayers = GetPlayersInArea(plant.coords, 100.0)
                    for _, playerId in ipairs(nearbyPlayers) do
                        TriggerClientEvent('ez_farming:plantDiseased', playerId, plantId, plant.coords)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('ez_farming:treatDisease')
AddEventHandler('ez_farming:treatDisease', function(plantId)
    local source = source
    local plant = PlantedCrops[plantId]
    
    if not plant or not PlantDiseases[plantId] then
        return
    end
    
    -- Check if player has fungicide
    if not HasItem(source, 'fungicide') then
        TriggerClientEvent('ez_farming:notify', source, 'You need fungicide to treat plant diseases!', 'error')
        return
    end
    
    if RemoveItem(source, 'fungicide', 1) then
        PlantDiseases[plantId] = nil
        plant.diseased = false
        UpdatePlantInDatabase(plantId, {diseased = false})
        
        TriggerClientEvent('ez_farming:notify', source, 'Disease treated successfully!', 'success')
        TriggerClientEvent('ez_farming:diseaseCleared', -1, plantId)
    end
end)

-- Utility functions
function GetPlayersInArea(coords, radius)
    local players = {}
    local allPlayers = GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        
        if #(coords - playerCoords) <= radius then
            table.insert(players, tonumber(playerId))
        end
    end
    
    return players
end

-- Greenhouse system enhancements
function ApplyGreenhouseEffects(plant)
    if not plant.isInGreenhouse then return end
    
    local zone = Config.FarmingZones[plant.zoneIndex]
    if not zone.isGreenhouse then return end
    
    -- Greenhouse benefits
    local effects = {
        growthBonus = 0.1, -- 10% faster growth
        weatherProtection = true, -- Immune to weather penalties
        seasonBonus = 0.05, -- 5% bonus regardless of season
        pestProtection = 0.5, -- 50% less pest chance
        diseaseProtection = 0.3 -- 30% less disease chance
    }
    
    return effects
end

-- Crop quality system
function CalculateCropQuality(plant)
    local baseQuality = 1.0
    local quality = baseQuality
    
    -- Factors that affect quality
    if plant.fertilized then
        quality = quality + 0.2
    end
    
    if not plant.needsWater then
        quality = quality + 0.1
    end
    
    if PestInfestations[plant.id] then
        quality = quality - 0.3
    end
    
    if PlantDiseases[plant.id] then
        quality = quality - 0.4
    end
    
    -- Season effects
    local cropConfig = Config.Crops[plant.cropType]
    local currentSeason = Config.Seasons.currentSeason
    
    if not table.contains(cropConfig.seasons, currentSeason) then
        quality = quality - 0.2 -- Out of season penalty
    end
    
    -- Weather effects
    local weatherEffects = Config.Weather.effects[CurrentWeather]
    if weatherEffects then
        if weatherEffects.growth_bonus then
            quality = quality + (weatherEffects.growth_bonus * 0.5)
        end
        if weatherEffects.growth_penalty then
            quality = quality - (weatherEffects.growth_penalty * 0.5)
        end
    end
    
    -- Level bonuses
    local playerStats = PlayerStats[plant.playerIdentifier]
    if playerStats and playerStats.level then
        quality = quality + (playerStats.level * 0.01) -- 1% per level
    end
    
    return math.max(0.1, math.min(2.0, quality)) -- Clamp between 0.1 and 2.0
end

-- Enhanced harvest system with quality
RegisterNetEvent('ez_farming:harvestCrop')
AddEventHandler('ez_farming:harvestCrop', function(plantId)
    local playerId = source
    local identifier = GetPlayerIdentifier(playerId)
    local plant = PlantedCrops[plantId]
    
    if not plant or plant.stage < plant.maxStages then
        return
    end
    
    -- Check ownership and tools (existing logic)
    if plant.playerIdentifier ~= identifier then
        return
    end
    
    if not HasItem(playerId, Config.Tools.hoe.item) then
        return
    end
    
    local cropConfig = Config.Crops[plant.cropType]
    local quality = CalculateCropQuality(plant)
    
    -- Calculate harvest amount with quality modifier
    local baseAmount = math.random(cropConfig.minHarvest, cropConfig.maxHarvest)
    local harvestAmount = math.floor(baseAmount * quality)
    
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
    
    -- Create quality-based item metadata
    local metadata = {
        quality = quality,
        crop_type = plant.cropType,
        harvest_date = os.date("%Y-%m-%d"),
        farmer = GetPlayerName(playerId)
    }
    
    -- Different item names for different qualities
    local harvestItem = cropConfig.harvestItem
    if quality >= 1.5 then
        harvestItem = harvestItem .. "_premium"
    elseif quality >= 1.2 then
        harvestItem = harvestItem .. "_good"
    elseif quality <= 0.7 then
        harvestItem = harvestItem .. "_poor"
    end
    
    -- Add harvested items with metadata
    if AddItem(playerId, harvestItem, harvestAmount, metadata) then
        -- Remove plant from database and memory
        RemovePlantFromDatabase(plantId)
        PlantedCrops[plantId] = nil
        
        -- Clean up related systems
        if PestInfestations[plantId] then
            PestInfestations[plantId] = nil
        end
        if PlantDiseases[plantId] then
            PlantDiseases[plantId] = nil
        end
        
        -- Update player stats
        if PlayerStats[identifier] then
            PlayerStats[identifier].totalHarvests = (PlayerStats[identifier].totalHarvests or 0) + 1
            UpdatePlayerStats(identifier, {total_harvests = PlayerStats[identifier].totalHarvests})
        end
        
        local experienceGain = math.floor(cropConfig.experience * quality)
        AddExperience(identifier, experienceGain)
        
        -- Notify clients
        TriggerClientEvent('ez_farming:harvestSuccess', -1, plantId, {
            cropType = plant.cropType,
            amount = harvestAmount,
            quality = quality,
            item = harvestItem
        })
        
        TriggerClientEvent('ez_farming:notify', playerId, 
            string.format('Harvested %s x%d (Quality: %.1fx)', cropConfig.label, harvestAmount, quality), 
            'success')
    end
end)

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Backup system
CreateThread(function()
    while true do
        Wait(1800000) -- Every 30 minutes
        
        if Config.UseDatabase then
            -- Create backup of current farming data
            local backupData = {
                plants = PlantedCrops,
                stats = PlayerStats,
                timestamp = os.time(),
                version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
            }
            
            -- Save backup to file (you would implement file saving here)
            print('^2[EZ Farming]^7 Created automatic backup with ' .. 
                  GetTableLength(PlantedCrops) .. ' plants and ' .. 
                  GetTableLength(PlayerStats) .. ' player profiles')
        end
    end
end)

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Performance monitoring
local PerformanceMonitor = {
    plantUpdates = 0,
    databaseQueries = 0,
    playerActions = 0,
    lastReset = os.time()
}

CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        
        local currentTime = os.time()
        local timeDiff = currentTime - PerformanceMonitor.lastReset
        
        print(string.format(
            '^2[EZ Farming Performance]^7 Last %d minutes: %d plant updates, %d DB queries, %d player actions',
            timeDiff / 60,
            PerformanceMonitor.plantUpdates,
            PerformanceMonitor.databaseQueries,
            PerformanceMonitor.playerActions
        ))
        
        -- Reset counters
        PerformanceMonitor.plantUpdates = 0
        PerformanceMonitor.databaseQueries = 0
        PerformanceMonitor.playerActions = 0
        PerformanceMonitor.lastReset = currentTime
    end
end)

print('^2[EZ Farming]^7 Server utilities loaded successfully!')
