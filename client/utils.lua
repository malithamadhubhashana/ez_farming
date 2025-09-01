-- Advanced client utilities and additional features
local CurrentWeather = 'CLEAR'
local CurrentSeason = 'spring'
local FarmingUI = {
    isOpen = false,
    currentMenu = nil
}

-- Global variables initialization
PlantedCrops = PlantedCrops or {}
PlantObjects = PlantObjects or {}
ShopPeds = ShopPeds or {}
FarmingZones = FarmingZones or {}

-- Import functions from main client file
local function ShowNotification(configKey, ...)
    if not Config.Notifications or not Config.Notifications[configKey] then return end
    
    local notifConfig = Config.Notifications[configKey]
    local message = string.format(notifConfig.message, ...)
    
    TriggerEvent('ez_farming:notify', message, notifConfig.type, notifConfig.duration)
end

-- Import HasItem function
local function HasItem(item, amount)
    local hasItem = false
    TriggerServerEvent('ez_farming:checkItemServer', item, amount or 1, function(result)
        hasItem = result
    end)
    return hasItem
end

-- Import menu functions
local function OpenFarmingMenu(zoneIndex)
    TriggerEvent('ez_farming:openFarmingMenuInternal', zoneIndex)
end

local function OpenShopMenu(shopIndex)
    TriggerEvent('ez_farming:openShopMenuInternal', shopIndex)
end

-- Weather sync
RegisterNetEvent('ez_farming:weatherSync')
AddEventHandler('ez_farming:weatherSync', function(weather)
    CurrentWeather = weather
end)

RegisterNetEvent('ez_farming:seasonChanged')
AddEventHandler('ez_farming:seasonChanged', function(season)
    CurrentSeason = season
    ShowNotification('season_change', 'Season changed to ' .. season)
end)

-- Custom Menu System (for non-ESX frameworks)
RegisterNetEvent('ez_farming:openCustomMenu')
AddEventHandler('ez_farming:openCustomMenu', function(menuData)
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    FarmingUI.currentMenu = menuData
    
    -- Send NUI message for custom UI
    SendNUIMessage({
        type = 'openMenu',
        data = menuData
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('ez_farming:openShopMenu')
AddEventHandler('ez_farming:openShopMenu', function(shopData)
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    
    SendNUIMessage({
        type = 'openShop',
        data = shopData
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('ez_farming:openAdminMenu')
AddEventHandler('ez_farming:openAdminMenu', function()
    if FarmingUI.isOpen then return end
    
    FarmingUI.isOpen = true
    
    local adminData = {
        title = 'Farming Admin Panel',
        options = {
            {label = 'View All Plants', value = 'view_plants'},
            {label = 'Remove All Plants', value = 'remove_all'},
            {label = 'Set Season', value = 'set_season'},
            {label = 'Set Weather', value = 'set_weather'},
            {label = 'Player Stats', value = 'player_stats'},
            {label = 'Reload Config', value = 'reload_config'}
        }
    }
    
    SendNUIMessage({
        type = 'openAdmin',
        data = adminData
    })
    SetNuiFocus(true, true)
end)

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    FarmingUI.isOpen = false
    FarmingUI.currentMenu = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

-- QB-Target event handlers (more robust)
RegisterNetEvent('ez_farming:openFarmingMenuTarget')
AddEventHandler('ez_farming:openFarmingMenuTarget', function(data)
    local zoneIndex = nil
    
    -- Handle different data formats that qb-target might send
    if type(data) == "table" then
        zoneIndex = data.zoneIndex
    elseif type(data) == "number" then
        zoneIndex = data
    end
    
    -- Fallback: try to get from entity or other means
    if not zoneIndex then
        -- Try to find closest farming zone
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestDistance = math.huge
        local closestZone = nil
        
        if Config.FarmingZones then
            for i, zone in ipairs(Config.FarmingZones) do
                local distance = #(playerCoords - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
                if distance < closestDistance and distance < 10.0 then
                    closestDistance = distance
                    closestZone = i
                end
            end
        end
        zoneIndex = closestZone
    end
    
    if zoneIndex then
        OpenFarmingMenu(zoneIndex)
    else
        print('^1[EZ Farming] Error: Could not determine farming zone index')
    end
end)

RegisterNetEvent('ez_farming:openShopMenuTarget')
AddEventHandler('ez_farming:openShopMenuTarget', function(data)
    local shopIndex = nil
    
    -- Handle different data formats that qb-target might send
    if type(data) == "table" then
        shopIndex = data.shopIndex
    elseif type(data) == "number" then
        shopIndex = data
    end
    
    if shopIndex then
        OpenShopMenu(shopIndex)
    else
        print('^1[EZ Farming] Error: Could not determine shop index')
    end
    end
end)

RegisterNetEvent('ez_farming:plantActionTarget')
AddEventHandler('ez_farming:plantActionTarget', function(data)
    local action = nil
    local plantId = nil
    
    -- Handle different data formats that qb-target might send
    if type(data) == "table" then
        action = data.action
        plantId = data.plantId
    end
    
    -- Validate data
    if not action or not plantId then
        print('^1[EZ Farming] Error: Missing action or plantId in plant target event')
        return
    end
    
    if action == 'water_plant' or action == 'water' then
        WaterPlant(plantId)
    elseif action == 'fertilize_plant' or action == 'fertilize' then
        FertilizePlant(plantId)
    elseif action == 'harvest_plant' or action == 'harvest' then
        HarvestPlant(plantId)
    elseif action == 'plant_info' then
        local plant = PlantedCrops[plantId]
        if plant then
            ShowPlantInfo(plant)
        end
    else
        print('^1[EZ Farming] Unknown plant action: ' .. tostring(action))
    end
end)

RegisterNUICallback('menuAction', function(data, cb)
    local action = data.action
    local value = data.value
    
    if FarmingUI.currentMenu then
        if string.find(action, 'plant_') then
            local cropType = string.gsub(action, 'plant_', '')
            PlantCrop(cropType, FarmingUI.currentMenu.zoneIndex)
        elseif action == 'zone_info' then
            ShowZoneInfo(FarmingUI.currentMenu.zoneIndex)
        end
    end
    
    FarmingUI.isOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('shopAction', function(data, cb)
    local action = data.action -- 'buy' or 'sell'
    local item = data.item
    local amount = data.amount or 1
    local shopIndex = data.shopIndex
    
    if action == 'buy' then
        TriggerServerEvent('ez_farming:buyItem', shopIndex, item, amount)
    elseif action == 'sell' then
        TriggerServerEvent('ez_farming:sellItem', shopIndex, item, amount)
    end
    
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    local action = data.action
    local value = data.value
    
    if action == 'view_plants' then
        TriggerServerEvent('ez_farming:adminViewPlants')
    elseif action == 'remove_all' then
        TriggerServerEvent('ez_farming:adminRemoveAll')
    elseif action == 'set_season' then
        TriggerServerEvent('ez_farming:adminSetSeason', value)
    elseif action == 'set_weather' then
        TriggerServerEvent('ez_farming:adminSetWeather', value)
    elseif action == 'player_stats' then
        TriggerServerEvent('ez_farming:adminPlayerStats', value)
    elseif action == 'reload_config' then
        TriggerServerEvent('ez_farming:adminReloadConfig')
    end
    
    cb('ok')
end)

-- Plant visual effects system
function CreatePlantObject(plantId, plant)
    local cropConfig = Config.Crops[plant.cropType]
    if not cropConfig or not cropConfig.model then return end
    
    local model = GetHashKey(cropConfig.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local object = CreateObject(model, plant.coords.x, plant.coords.y, plant.coords.z, false, false, false)
    SetEntityHeading(object, math.random(0, 360))
    
    -- Scale based on growth stage
    local scale = 0.3 + (plant.stage / plant.maxStages * 0.7)
    SetEntityScale(object, scale, scale, scale)
    
    -- Store object reference
    if not PlantObjects then PlantObjects = {} end
    PlantObjects[plantId] = object
    
    return object
end

function UpdatePlantVisuals()
    if not PlantObjects then PlantObjects = {} end
    if not PlantedCrops then return end -- Exit if PlantedCrops is nil
    
    for plantId, plant in pairs(PlantedCrops) do
        if PlantObjects[plantId] then
            -- Update existing plant visual
            local scale = 0.3 + (plant.stage / plant.maxStages * 0.7)
            SetEntityScale(PlantObjects[plantId], scale, scale, scale)
        else
            -- Create new plant visual
            CreatePlantObject(plantId, plant)
        end
    end
    
    -- Remove objects for harvested plants
    for plantId, object in pairs(PlantObjects) do
        if not PlantedCrops[plantId] then
            DeleteEntity(object)
            PlantObjects[plantId] = nil
        end
    end
end

-- Enhanced plant interaction system
function GetPlantInteractionOptions(plantId)
    local plant = PlantedCrops[plantId]
    if not plant then return {} end
    
    local options = {}
    local cropConfig = Config.Crops[plant.cropType]
    
    if plant.stage >= plant.maxStages then
        table.insert(options, {
            label = 'Harvest ' .. cropConfig.label,
            icon = 'fas fa-hand-paper',
            action = function()
                if HasItem(Config.Tools.hoe.item) then
                    TriggerServerEvent('ez_farming:harvestCrop', plantId)
                else
                    ShowNotification('no_tool', Config.Tools.hoe.label)
                end
            end
        })
    end
    
    if plant.needsWater then
        table.insert(options, {
            label = 'Water Plant',
            icon = 'fas fa-tint',
            action = function()
                if HasItem(Config.Tools.watering_can.item) then
                    TriggerServerEvent('ez_farming:waterPlant', plantId)
                    -- Play watering animation
                    PlayWateringAnimation()
                else
                    ShowNotification('no_tool', Config.Tools.watering_can.label)
                end
            end
        })
    end
    
    if cropConfig.fertilizerCompatible and not plant.fertilized and HasItem(Config.Tools.fertilizer.item) then
        table.insert(options, {
            label = 'Apply Fertilizer',
            icon = 'fas fa-seedling',
            action = function()
                TriggerServerEvent('ez_farming:fertilizePlant', plantId)
                PlayFertilizingAnimation()
            end
        })
    end
    
    table.insert(options, {
        label = 'Plant Information',
        icon = 'fas fa-info-circle',
        action = function()
            ShowPlantInfo(plant)
        end
    })
    
    return options
end

-- Animation system
function PlayPlantingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(playerPed)
end

function PlayWateringAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    -- Create watering can prop
    local prop = CreateObject(GetHashKey('prop_wateringcan'), 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(prop, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(3000)
    
    DeleteEntity(prop)
    ClearPedTasks(playerPed)
end

function PlayFertilizingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
end

function PlayHarvestingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@world_human_gardener_plant@male@base"
    local animName = "base"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(4000)
    ClearPedTasks(playerPed)
end

-- Information display system
function ShowPlantInfo(plant)
    local cropConfig = Config.Crops[plant.cropType]
    local growthProgress = math.floor((plant.stage / plant.maxStages) * 100)
    
    local info = string.format([[
<div style="background: rgba(0,0,0,0.8); color: white; padding: 20px; border-radius: 10px; max-width: 300px;">
    <h3>%s</h3>
    <p><strong>Growth:</strong> Stage %d/%d (%d%%)</p>
    <p><strong>Status:</strong> %s</p>
    <p><strong>Watered:</strong> %s</p>
    <p><strong>Fertilized:</strong> %s</p>
    <p><strong>Season:</strong> %s</p>
    <p><strong>Weather Effects:</strong> %s</p>
</div>
    ]], 
    cropConfig.label,
    plant.stage, plant.maxStages, growthProgress,
    plant.stage >= plant.maxStages and "Ready to Harvest" or "Growing",
    plant.needsWater and "No" or "Yes",
    plant.fertilized and "Yes" or "No",
    CurrentSeason,
    GetWeatherEffectDescription()
    )
    
    SendNUIMessage({
        type = 'showInfo',
        data = {
            html = info,
            duration = 10000
        }
    })
end

function GetWeatherEffectDescription()
    local effects = Config.Weather.effects[CurrentWeather]
    if not effects then return "None" end
    
    local descriptions = {}
    
    if effects.growth_bonus then
        table.insert(descriptions, string.format("+%.0f%% Growth", effects.growth_bonus * 100))
    end
    if effects.growth_penalty then
        table.insert(descriptions, string.format("-%.0f%% Growth", effects.growth_penalty * 100))
    end
    if effects.water_bonus then
        table.insert(descriptions, string.format("+%.0f%% Water Eff.", effects.water_bonus * 100))
    end
    if effects.water_penalty then
        table.insert(descriptions, string.format("-%.0f%% Water Eff.", effects.water_penalty * 100))
    end
    
    return #descriptions > 0 and table.concat(descriptions, ", ") or "None"
end

-- Enhanced notification system
RegisterNetEvent('ez_farming:notify')
AddEventHandler('ez_farming:notify', function(message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if Framework == 'esx' then
        ESX.ShowNotification(message)
    elseif Framework == 'qb' then
        QBCore.Functions.Notify(message, type, duration)
    elseif Framework == 'qbx' then
        exports.qbx_core:Notify(message, type, duration)
    else
        -- Custom notification for standalone
        SendNUIMessage({
            type = 'notification',
            data = {
                message = message,
                type = type,
                duration = duration
            }
        })
    end
end)

-- Farming statistics tracking
local FarmingStats = {
    plantsWatered = 0,
    plantsFertilized = 0,
    plantsHarvested = 0,
    sessionTime = 0
}

CreateThread(function()
    while true do
        Wait(60000) -- Update every minute
        FarmingStats.sessionTime = FarmingStats.sessionTime + 1
        
        -- Send stats to server every 5 minutes
        if FarmingStats.sessionTime % 5 == 0 then
            TriggerServerEvent('ez_farming:updateSessionStats', FarmingStats)
        end
    end
end)

-- Event handlers for stat tracking
RegisterNetEvent('ez_farming:waterSuccess')
AddEventHandler('ez_farming:waterSuccess', function(plantId)
    FarmingStats.plantsWatered = FarmingStats.plantsWatered + 1
    -- Original water success logic
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].needsWater = false
        PlantedCrops[plantId].lastWaterTime = GetGameTimer()
    end
    ShowNotification('water_success')
end)

RegisterNetEvent('ez_farming:fertilizeSuccess')
AddEventHandler('ez_farming:fertilizeSuccess', function(plantId)
    FarmingStats.plantsFertilized = FarmingStats.plantsFertilized + 1
    -- Original fertilize success logic
    if PlantedCrops[plantId] then
        PlantedCrops[plantId].fertilized = true
    end
    ShowNotification('fertilize_success')
end)

RegisterNetEvent('ez_farming:harvestSuccess')
AddEventHandler('ez_farming:harvestSuccess', function(plantId, harvestData)
    FarmingStats.plantsHarvested = FarmingStats.plantsHarvested + 1
    -- Original harvest success logic
    PlantedCrops[plantId] = nil
    ShowNotification('harvest_success', Config.Crops[harvestData.cropType].label, harvestData.amount)
    
    -- Play harvest animation and effects
    PlayHarvestingAnimation()
end)

-- Visual effects system
CreateThread(function()
    while true do
        Wait(5000) -- Update visuals every 5 seconds
        UpdatePlantVisuals()
    end
end)

-- Target system integration (if qb-target or ox_target is available)
CreateThread(function()
    if not Config.UseTarget then return end
    
    Wait(2000) -- Wait for resources to load
    
    local targetResource = nil
    if GetResourceState('ox_target') == 'started' then
        targetResource = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        targetResource = 'qb-target'
    end
    
    if not targetResource then
        print('^3[EZ Farming]^7 No target system found, using drawtext system')
        return
    end
    
    print('^2[EZ Farming]^7 Using target system: ' .. targetResource)
    
    -- Debug: Check if Config tables exist
    if Config.Debug then
        print('^2[EZ Farming Debug]^7 Config.FarmingZones exists: ' .. tostring(Config.FarmingZones ~= nil))
        if Config.FarmingZones then
            print('^2[EZ Farming Debug]^7 Number of farming zones: ' .. #Config.FarmingZones)
        end
        print('^2[EZ Farming Debug]^7 Config.Shops exists: ' .. tostring(Config.Shops ~= nil))
        if Config.Shops then
            print('^2[EZ Farming Debug]^7 Number of shops: ' .. #Config.Shops)
        end
    end
    
    -- Add target zones for farming areas
    if Config.FarmingZones then
        for i, zone in ipairs(Config.FarmingZones) do
            if zone and zone.coords then
                local options = {
                    {
                        name = "ez_farming_zone_" .. i,
                        icon = "fas fa-seedling",
                        label = "Open Farming Menu",
                        onSelect = function()
                            OpenFarmingMenu(i)
                        end,
                        distance = Config.MaxDistance
                    }
                }
                
                if targetResource == 'ox_target' then
                    exports.ox_target:addBoxZone({
                        coords = zone.coords,
                        size = zone.size,
                        rotation = zone.rotation or 0,
                        debug = Config.Debug,
                        options = options
                    })
                elseif targetResource == 'qb-target' then
                    -- QB-Target requires different structure with safety checks
                    local coords = vector3(zone.coords.x or 0, zone.coords.y or 0, zone.coords.z or 0)
                    local sizeX = zone.size and zone.size.x or 5.0
                    local sizeY = zone.size and zone.size.y or 5.0
                    local sizeZ = zone.size and zone.size.z or 2.0
                    local heading = zone.rotation or 0.0
                    
                    if Config.Debug then
                        print(string.format('^2[EZ Farming Debug]^7 Adding QB-Target zone %d at %s', i, tostring(coords)))
                    end
                    
                    pcall(function()
                        exports['qb-target']:AddBoxZone("farming_zone_" .. i, coords, sizeX, sizeY, {
                            name = "farming_zone_" .. i,
                            heading = heading,
                            debugPoly = Config.Debug,
                            minZ = coords.z - sizeZ / 2,
                            maxZ = coords.z + sizeZ / 2,
                        }, {
                            options = {
                                {
                                    type = "client",
                                    event = "ez_farming:openFarmingMenuTarget",
                                    icon = "fas fa-seedling",
                                    label = "Open Farming Menu",
                                    zoneIndex = i
                                }
                            },
                            distance = Config.MaxDistance
                        })
                    end)
                    
                    if Config.Debug then
                        print('^2[EZ Farming Debug]^7 Successfully added QB-Target zone: ' .. i)
                    end
                end
            end -- End if zone and zone.coords
        end -- End for zones
    end -- End if Config.FarmingZones
    
    -- Add target for shop peds
    if Config.Shops then
        for i, shop in ipairs(Config.Shops) do
            if shop.ped then
                CreateThread(function()
                    Wait(3000) -- Wait for peds to spawn
                    if ShopPeds and ShopPeds[i] then
                        local ped = ShopPeds[i]
                        if ped and DoesEntityExist(ped) then
                            if targetResource == 'ox_target' then
                                local options = {
                                    {
                                        name = "ez_farming_shop_" .. i,
                                        icon = "fas fa-shopping-cart",
                                        label = "Open " .. shop.name,
                                        onSelect = function()
                                            OpenShopMenu(i)
                                        end,
                                        distance = Config.MaxDistance
                                    }
                                }
                                exports.ox_target:addLocalEntity(ped, options)
                            elseif targetResource == 'qb-target' then
                                exports['qb-target']:AddTargetEntity(ped, {
                                    options = {
                                        {
                                            type = "client",
                                            event = "ez_farming:openShopMenuTarget",
                                            icon = "fas fa-shopping-cart",
                                            label = "Open " .. shop.name,
                                            shopIndex = i
                                        }
                                    },
                                    distance = Config.MaxDistance
                        })
                    end
                end
                end) -- End CreateThread
            end -- End if shop.ped
        end -- End for shop loop
    end -- End if Config.Shops
    
    -- Add dynamic targets for planted crops
    CreateThread(function()
        local addedTargets = {}
        
        while true do
            Wait(5000) -- Check every 5 seconds
            
            -- Remove targets for harvested plants
            if addedTargets then
                for plantId, _ in pairs(addedTargets) do
                    if not PlantedCrops or not PlantedCrops[plantId] then
                        if targetResource == 'ox_target' then
                            exports.ox_target:removeZone('plant_' .. plantId)
                        elseif targetResource == 'qb-target' then
                            exports['qb-target']:RemoveZone('plant_' .. plantId)
                        end
                        addedTargets[plantId] = nil
                    end
                end
            end
            
            -- Add targets for new plants
            local playerCoords = GetEntityCoords(PlayerPedId())
            if PlantedCrops and Config.Crops then
                for plantId, plant in pairs(PlantedCrops) do
                    if not addedTargets[plantId] and #(playerCoords - plant.coords) < 50.0 then
                        local cropConfig = Config.Crops[plant.cropType]
                        if cropConfig then
                            local options = {}
                            
                            if plant.stage >= plant.maxStages then
                                table.insert(options, {
                                    name = "harvest_plant",
                                    icon = "fas fa-hand-paper",
                                    label = "Harvest " .. cropConfig.label,
                                    onSelect = function()
                                        InteractWithPlant(plantId)
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.hoe.item)
                            end
                        })
                    end
                    
                    if plant.needsWater then
                        table.insert(options, {
                            name = "water_plant",
                            icon = "fas fa-tint",
                            label = "Water Plant",
                            onSelect = function()
                                if HasItem(Config.Tools.watering_can.item) then
                                    TriggerServerEvent('ez_farming:waterPlant', plantId)
                                    PlayWateringAnimation()
                                else
                                    ShowNotification('no_tool', Config.Tools.watering_can.label)
                                end
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.watering_can.item)
                            end
                        })
                    end
                    
                    if cropConfig.fertilizerCompatible and not plant.fertilized and HasItem(Config.Tools.fertilizer.item) then
                        table.insert(options, {
                            name = "fertilize_plant",
                            icon = "fas fa-seedling",
                            label = "Apply Fertilizer",
                            onSelect = function()
                                TriggerServerEvent('ez_farming:fertilizePlant', plantId)
                                PlayFertilizingAnimation()
                            end,
                            canInteract = function()
                                return HasItem(Config.Tools.fertilizer.item)
                            end
                        })
                    end
                    
                    table.insert(options, {
                        name = "plant_info",
                        icon = "fas fa-info-circle",
                        label = "Plant Information",
                        onSelect = function()
                            ShowPlantInfo(plant)
                        end
                    })
                    
                    if #options > 0 then
                        if targetResource == 'ox_target' then
                            exports.ox_target:addSphereZone({
                                coords = plant.coords,
                                radius = 1.0,
                                debug = Config.Debug,
                                options = options
                            })
                        elseif targetResource == 'qb-target' then
                            -- Convert ox_target options format to qb-target format
                            local qbOptions = {}
                            for _, option in pairs(options) do
                                table.insert(qbOptions, {
                                    type = "client",
                                    event = "ez_farming:plantActionTarget",
                                    icon = option.icon,
                                    label = option.label,
                                    action = option.name,
                                    plantId = plantId
                                })
                            end
                            
                            exports['qb-target']:AddCircleZone('plant_' .. plantId, vector3(plant.coords.x, plant.coords.y, plant.coords.z), 1.0, {
                                name = 'plant_' .. plantId,
                                debugPoly = Config.Debug,
                            }, {
                                options = qbOptions,
                                distance = Config.MaxDistance
                            })
                        end
                        
                        addedTargets[plantId] = true
                    end -- End if #options > 0
                        end -- End if cropConfig
                    end -- End if not addedTargets[plantId]
                end -- End for plantId, plant in pairs(PlantedCrops)
            end -- End if PlantedCrops and Config.Crops
        end -- End while true
    end) -- End CreateThread
end) -- End main CreateThread

-- Target events
RegisterNetEvent('ez_farming:openFarmingMenu')
AddEventHandler('ez_farming:openFarmingMenu', function(data)
    OpenFarmingMenu(data.zoneIndex)
end)

RegisterNetEvent('ez_farming:openFarmingMenuTarget')
AddEventHandler('ez_farming:openFarmingMenuTarget', function(data)
    OpenFarmingMenu(data.zoneIndex)
end)

RegisterNetEvent('ez_farming:openShopMenuTarget')
AddEventHandler('ez_farming:openShopMenuTarget', function(data)
    OpenShopMenu(data.shopIndex)
end)

-- Enhanced debug system
if Config.Debug then
    CreateThread(function()
        while true do
            Wait(1000)
            
            -- Debug info on screen
            local playerCoords = GetEntityCoords(PlayerPedId())
            local debugText = string.format(
                "Framework: %s\nWeather: %s\nSeason: %s\nPlants Loaded: %d\nCoords: %.2f, %.2f, %.2f",
                Framework or 'Unknown',
                CurrentWeather,
                CurrentSeason,
                GetTableLength(PlantedCrops),
                playerCoords.x, playerCoords.y, playerCoords.z
            )
            
            SetTextFont(0)
            SetTextScale(0.3, 0.3)
            SetTextColour(255, 255, 255, 255)
            SetTextEntry("STRING")
            AddTextComponentSubstringPlayerName(debugText)
            DrawText(0.01, 0.01)
        end
    end)
end

function GetTableLength(t)
    if not t then return 0 end -- Add nil check
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print('^2[EZ Farming]^7 Client utilities loaded successfully!')
